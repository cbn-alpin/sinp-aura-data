-- Create materialized views to enhance synthese export view
-- Required rights: DB OWNER
-- Transfert this script on server this way:
-- rsync -av ./010_* geonat@db-aura-sinp:~/data/db-geonature/data/sql/ --dry-run
-- Use this script this way: psql -h localhost -U geonatadmin -d geonature2db -f ~/data/db-geonature/data/sql/010_*

\timing on

BEGIN;

\echo '----------------------------------------------------------------------------'
\echo 'Create function to drop any type of view if exists'

CREATE OR REPLACE FUNCTION drop_any_type_of_view_if_exists(IN viewToDelete text)
RETURNS VOID AS
$$
DECLARE viewKind TEXT ;
DECLARE viewSchema TEXT ;
BEGIN
    RAISE LOG 'Looking for (materialized) view named %', viewToDelete;
    SELECT relkind INTO viewKind FROM pg_class WHERE relname = viewToDelete ;
    IF viewKind = 'm' THEN
        SELECT schemaname INTO viewSchema FROM pg_matviews WHERE matviewname = viewToDelete ;
        RAISE NOTICE 'Dropping MATERIALIZED VIEW %.%', viewSchema, viewToDelete ;
        EXECUTE 'DROP MATERIALIZED VIEW ' ||  quote_ident(viewSchema) || '.' || quote_ident(viewToDelete);
    ELSEIF viewKind = 'v' THEN
        SELECT schemaname INTO viewSchema FROM pg_views WHERE viewname = viewToDelete ;
        RAISE NOTICE 'Dropping VIEW %.%', viewSchema, viewToDelete;
        EXECUTE 'DROP VIEW ' ||  quote_ident(viewSchema) || '.' || quote_ident(viewToDelete);
    ELSE
        RAISE NOTICE 'NO VIEW % found', viewToDelete;
    END IF;
END;
$$ LANGUAGE plpgsql;


\echo '----------------------------------------------------------------------------'
\echo 'Drop all TMP materialized views if exist'

DROP MATERIALIZED VIEW IF EXISTS gn_synthese.v_synthese_for_export_tmp ;
DROP MATERIALIZED VIEW IF EXISTS gn_synthese.synthese_status_tmp ;
DROP MATERIALIZED VIEW IF EXISTS taxonomie.taxon_area_status_tmp ;
DROP MATERIALIZED VIEW IF EXISTS gn_synthese.synthese_municipality_tmp ;


\echo '----------------------------------------------------------------------------'
\echo 'Create MATERIALIZED VIEW gn_synthese.synthese_municipality_tmp'

CREATE MATERIALIZED VIEW gn_synthese.synthese_municipality_tmp
TABLESPACE pg_default AS
  SELECT
    cas.id_synthese,
    string_agg(DISTINCT concat(a.area_name, ' (', a.area_code, ')'), ', '::text) AS municipalities
  FROM gn_synthese.cor_area_synthese AS cas
    JOIN ref_geo.l_areas AS a
      ON cas.id_area = a.id_area
    JOIN ref_geo.bib_areas_types AS ta
      ON ta.id_type = a.id_type AND ta.type_code::text = 'COM'::text
  GROUP BY cas.id_synthese
WITH DATA;

CREATE UNIQUE INDEX synthese_municipality_id_synthese_idx_tmp ON gn_synthese.synthese_municipality_tmp
USING btree (id_synthese);


\echo '----------------------------------------------------------------------------'
\echo 'Create MATERIALIZED VIEW taxonomie.taxon_area_status_tmp'

CREATE MATERIALIZED VIEW taxonomie.taxon_area_status_tmp
TABLESPACE pg_default AS
  WITH agg_code_status AS (
    SELECT
      ta.cd_ref,
      cta.id_area,
      te.cd_type_statut,
      jsonb_agg(DISTINCT bsv.code_statut) AS code_statuts
    FROM taxonomie.bdc_statut_taxons AS ta
      JOIN taxonomie.bdc_statut_cor_text_values AS bsctv
        ON bsctv.id_value_text = ta.id_value_text
      JOIN taxonomie.bdc_statut_text AS te
        ON te.id_text = bsctv.id_text
      JOIN taxonomie.bdc_statut_cor_text_area AS cta
        ON cta.id_text = te.id_text
      LEFT JOIN taxonomie.bdc_statut_values AS bsv
        ON bsv.id_value = bsctv.id_value
    GROUP BY ta.cd_ref, cta.id_area, te.cd_type_statut
  )
  SELECT
    acs.cd_ref,
    acs.id_area,
    jsonb_object_agg(acs.cd_type_statut, acs.code_statuts) AS status
  FROM agg_code_status acs
  GROUP BY acs.cd_ref, acs.id_area
WITH DATA;

CREATE UNIQUE INDEX taxon_area_status_cd_ref_id_area_idx_tmp ON taxonomie.taxon_area_status_tmp
USING btree (cd_ref, id_area);
CREATE INDEX taxon_area_status_status_idx_tmp ON taxonomie.taxon_area_status_tmp
USING gin (status);


\echo '----------------------------------------------------------------------------'
\echo 'Create MATERIALIZED VIEW gn_synthese.synthese_status_tmp'

CREATE MATERIALIZED VIEW gn_synthese.synthese_status_tmp
TABLESPACE pg_default AS
  WITH depts AS (
    SELECT id_area
    FROM ref_geo.l_areas
    WHERE id_type = ref_geo.get_id_area_type_by_code('DEP')
      AND "enable" = TRUE
  ),
  obs_multi_depts AS (
    SELECT cas.id_synthese
    FROM gn_synthese.cor_area_synthese AS cas
      JOIN depts AS d
        ON d.id_area = cas.id_area
    GROUP BY cas.id_synthese
    HAVING COUNT(cas.id_area) > 1
    ORDER BY cas.id_synthese
  ),
  obs_status_by_dept AS (
    SELECT
      s.id_synthese,
      a.area_code,
      (
        SELECT string_agg(status, ', ')
        FROM jsonb_array_elements_text(tas.status -> 'PN') AS tmp(status)
      ) AS status_pn,
      (
        SELECT string_agg(status, ', ')
        FROM jsonb_array_elements_text(tas.status -> 'PR') AS tmp(status)
      ) AS status_pr,
      (
        SELECT string_agg(status, ', ')
        FROM jsonb_array_elements_text(tas.status -> 'PD') AS tmp(status)
      ) AS status_pd,
      (
        SELECT string_agg(status, ', ')
        FROM jsonb_array_elements_text(tas.status -> 'LRN') AS tmp(status)
      ) AS status_lrn,
      (
        SELECT string_agg(status, ', ')
        FROM jsonb_array_elements_text(tas.status -> 'LRR') AS tmp(status)
      ) AS status_lrr,
      (
        SELECT string_agg(status, ', ')
        FROM jsonb_array_elements_text(tas.status -> 'LRD') AS tmp(status)
      ) AS status_lrd,
      CASE (
          SELECT string_agg(status, ', ')
          FROM jsonb_array_elements_text(tas.status -> 'ZDET') AS tmp(status)
        )
        WHEN 'true' THEN 'OUI'
        WHEN 'false' THEN 'NON'
        ELSE NULL
      END AS status_zdet,
      (
        SELECT string_agg(status, ', ')
        FROM jsonb_array_elements_text(tas.status -> 'DH') AS tmp(status)
      ) AS status_dh,
      (
        SELECT string_agg(status, ', ')
        FROM jsonb_array_elements_text(tas.status -> 'DO') AS tmp(status)
      ) AS status_do
    FROM gn_synthese.synthese AS s
      LEFT JOIN taxonomie.taxref AS t
        ON t.cd_nom = s.cd_nom
      LEFT JOIN gn_synthese.cor_area_synthese AS cas
        ON s.id_synthese = cas.id_synthese
      JOIN taxonomie.taxon_area_status_tmp AS tas
        ON cas.id_area = tas.id_area AND t.cd_ref = tas.cd_ref
      JOIN ref_geo.l_areas AS a
        ON cas.id_area = a.id_area
    WHERE s.id_synthese IN (SELECT id_synthese FROM obs_multi_depts)
  )
  SELECT
    id_synthese,
    CASE
      WHEN count(DISTINCT status_pn) > 1
        THEN string_agg(concat(status_pn, ' (', area_code, ')'), '|')
        ELSE string_agg(DISTINCT status_pn, '|')
    END AS status_pn,
    CASE
      WHEN count(DISTINCT status_pr) > 1
        THEN string_agg(concat(status_pr, ' (', area_code, ')'), '|')
        ELSE string_agg(DISTINCT status_pr, '|')
    END AS status_pr,
    CASE
      WHEN count(DISTINCT status_pd) > 1
        THEN string_agg(concat(status_pd, ' (', area_code, ')'), '|')
        ELSE string_agg(DISTINCT status_pd, '|')
    END AS status_pd,
    CASE
      WHEN count(DISTINCT status_lrn) > 1
        THEN string_agg(concat(status_lrn, ' (', area_code, ')'), '|')
        ELSE string_agg(DISTINCT status_lrn, '|')
    END AS status_lrn,
    CASE
      WHEN count(DISTINCT status_lrr) > 1
        THEN string_agg(concat(status_lrr, ' (', area_code, ')'), '|')
        ELSE string_agg(DISTINCT status_lrr, '|')
    END AS status_lrr,
    CASE
      WHEN count(DISTINCT status_lrd) > 1
        THEN string_agg(concat(status_lrd, ' (', area_code, ')'), '|')
        ELSE string_agg(DISTINCT status_lrd, '|')
    END AS status_lrd,
    CASE
      WHEN count(DISTINCT status_zdet) > 1
        THEN string_agg(concat(status_zdet, ' (', area_code, ')'), '|')
        ELSE string_agg(DISTINCT status_zdet, '|')
    END AS status_zdet,
    CASE
      WHEN count(DISTINCT status_dh) > 1
        THEN string_agg(concat(status_dh, ' (', area_code, ')'), '|')
        ELSE string_agg(DISTINCT status_dh, '|')
    END AS status_dh,
    CASE
      WHEN count(DISTINCT status_do) > 1
        THEN string_agg(concat(status_do, ' (', area_code, ')'), '|')
        ELSE string_agg(DISTINCT status_do, '|')
    END AS status_do
  FROM obs_status_by_dept
  GROUP BY id_synthese

  UNION

  SELECT
      s.id_synthese,
      (
        SELECT string_agg(status, ', ')
        FROM jsonb_array_elements_text(tas.status -> 'PN') AS tmp(status)
      ) AS status_pn,
      (
        SELECT string_agg(status, ', ')
        FROM jsonb_array_elements_text(tas.status -> 'PR') AS tmp(status)
      ) AS status_pr,
      (
        SELECT string_agg(status, ', ')
        FROM jsonb_array_elements_text(tas.status -> 'PD') AS tmp(status)
      ) AS status_pd,
      (
        SELECT string_agg(status, ', ')
        FROM jsonb_array_elements_text(tas.status -> 'LRN') AS tmp(status)
      ) AS status_lrn,
      (
        SELECT string_agg(status, ', ')
        FROM jsonb_array_elements_text(tas.status -> 'LRR') AS tmp(status)
      ) AS status_lrr,
      (
        SELECT string_agg(status, ', ')
        FROM jsonb_array_elements_text(tas.status -> 'LRD') AS tmp(status)
      ) AS status_lrd,
      CASE (
          SELECT string_agg(status, ', ')
          FROM jsonb_array_elements_text(tas.status -> 'ZDET') AS tmp(status)
        )
        WHEN 'true' THEN 'OUI'
        WHEN 'false' THEN 'NON'
        ELSE NULL
      END AS status_zdet,
      (
        SELECT string_agg(status, ', ')
        FROM jsonb_array_elements_text(tas.status -> 'DH') AS tmp(status)
      ) AS status_dh,
      (
        SELECT string_agg(status, ', ')
        FROM jsonb_array_elements_text(tas.status -> 'DO') AS tmp(status)
      ) AS status_do
    FROM gn_synthese.synthese AS s
      LEFT JOIN taxonomie.taxref AS t
        ON t.cd_nom = s.cd_nom
      LEFT JOIN gn_synthese.cor_area_synthese AS cas
        ON s.id_synthese = cas.id_synthese
      JOIN taxonomie.taxon_area_status_tmp AS tas
        ON cas.id_area = tas.id_area AND t.cd_ref = tas.cd_ref
    WHERE s.id_synthese NOT IN (SELECT id_synthese FROM obs_multi_depts)
WITH DATA;

CREATE UNIQUE INDEX synthese_status_id_synthese_idx_tmp ON gn_synthese.synthese_status_tmp
USING btree (id_synthese);


\echo '----------------------------------------------------------------------------'
\echo 'Create MATERIALIZED VIEW gn_synthese.v_synthese_for_export_tmp'

CREATE MATERIALIZED VIEW gn_synthese.v_synthese_for_export_tmp
TABLESPACE pg_default AS
  SELECT
    s.id_synthese,
    s.unique_id_sinp AS uuid_perm_sinp,
    s.unique_id_sinp_grp AS uuid_perm_grp_sinp,
    sd.dataset_name AS jdd_nom,
    sd.unique_dataset_id AS jdd_uuid,
    sd.organisms AS fournisseur,
    s.observers AS observateurs,
    s.determiner AS determinateurs,
    t.cd_ref,
    t.nom_valide,
    t.nom_vern AS nom_vernaculaire,
    t.classe,
    t.famille,
    t.ordre,
    n15.label_default AS statut_observation,
    s.count_min AS nombre_min,
    s.count_max AS nombre_max,
    s.date_min::date AS date_debut,
    s.date_max::date AS date_fin,
    st_asgeojson(s.the_geom_4326) AS geojson_4326,
    st_x(st_transform(st_centroid(s.the_geom_point), 4326)) AS x_centroid_4326,
    st_y(st_transform(st_centroid(s.the_geom_point), 4326)) AS y_centroid_4326,
    s."precision" AS precision_geographique,
    sm.municipalities AS communes,
    s.altitude_min AS alti_min,
    n3.label_default AS technique_observation,
    n10.label_default AS stade_vie,
    n5.label_default AS statut_biologique,
    n11.label_default AS sexe,
    n20.label_default AS comportement,
    n17.label_default AS type_source,
    s.additional_data ->> 'precisionLabel' AS type_precision,
    CASE
      WHEN ns.cd_nomenclature::text = '0'::text THEN 'donnée non sensible'
      WHEN s.id_nomenclature_sensitivity IS NULL THEN ''
      ELSE 'donnée sensible'
    END AS sensibilite,
    CASE
      WHEN ns.cd_nomenclature::text <> '0' OR dl.cd_nomenclature::text <> '5'
        THEN 'donnée confidentielle'
      ELSE 'donnée non confidentielle'
    END AS confidentialite,
    COALESCE(nb.cd_nomenclature, 'NON') AS floutage,
    vs.label_default AS statut_validation,
    ss.status_pn AS statut_pn,
    ss.status_pr AS statut_pr,
    ss.status_pd AS statut_pd,
    ss.status_lrn AS statut_lrn,
    ss.status_lrr AS statut_lrr,
    ss.status_lrd AS statut_lrd,
    ss.status_zdet AS statut_zdet,
    ss.status_dh AS statut_dh,
    ss.status_do AS statut_do,
    sd.id_dataset AS jdd_id,
    s.id_digitiser,
    st_asgeojson(s.the_geom_local) AS geojson_local,
    s.id_nomenclature_sensitivity,
    s.id_nomenclature_diffusion_level
  FROM gn_synthese.synthese AS s
    JOIN taxonomie.taxref AS t
      ON t.cd_nom = s.cd_nom
    LEFT JOIN gn_synthese.synthese_municipality_tmp AS sm
      ON sm.id_synthese = s.id_synthese
    LEFT JOIN LATERAL (
        SELECT td.id_dataset,
          td.dataset_name,
          td.unique_dataset_id,
          string_agg(DISTINCT bo.nom_organisme::text, ', '::text) AS organisms
        FROM gn_meta.t_datasets td
          LEFT JOIN gn_meta.cor_dataset_actor AS cad
            ON cad.id_dataset = td.id_dataset
              AND (
                cad.id_nomenclature_actor_role = ref_nomenclatures.get_id_nomenclature(
                  'ROLE_ACTEUR',
                  '5'
                )
                OR cad.id_nomenclature_actor_role = ref_nomenclatures.get_id_nomenclature(
                  'ROLE_ACTEUR',
                  '6'
                )
              )
          LEFT JOIN utilisateurs.bib_organismes AS bo
            ON bo.id_organisme = cad.id_organism
        WHERE td.id_dataset = s.id_dataset
        GROUP BY td.id_dataset
      ) AS sd ON true
    LEFT JOIN ref_nomenclatures.t_nomenclatures AS n3
      ON s.id_nomenclature_obs_technique = n3.id_nomenclature
    LEFT JOIN ref_nomenclatures.t_nomenclatures AS n5
      ON s.id_nomenclature_bio_status = n5.id_nomenclature
    LEFT JOIN ref_nomenclatures.t_nomenclatures AS n10
      ON s.id_nomenclature_life_stage = n10.id_nomenclature
    LEFT JOIN ref_nomenclatures.t_nomenclatures AS n11
      ON s.id_nomenclature_sex = n11.id_nomenclature
    LEFT JOIN ref_nomenclatures.t_nomenclatures AS n15
      ON s.id_nomenclature_observation_status = n15.id_nomenclature
    LEFT JOIN ref_nomenclatures.t_nomenclatures AS n17
      ON s.id_nomenclature_source_status = n17.id_nomenclature
    LEFT JOIN ref_nomenclatures.t_nomenclatures AS n20
      ON s.id_nomenclature_behaviour = n20.id_nomenclature
    LEFT JOIN ref_nomenclatures.t_nomenclatures AS ns
      ON s.id_nomenclature_sensitivity = ns.id_nomenclature
    LEFT JOIN ref_nomenclatures.t_nomenclatures AS dl
      ON s.id_nomenclature_diffusion_level = dl.id_nomenclature
    LEFT JOIN ref_nomenclatures.t_nomenclatures AS nb
      ON s.id_nomenclature_blurring = nb.id_nomenclature
    LEFT JOIN ref_nomenclatures.t_nomenclatures AS vs
      ON s.id_nomenclature_valid_status = vs.id_nomenclature
    LEFT JOIN gn_synthese.synthese_status_tmp AS ss
      ON s.id_synthese = ss.id_synthese
WITH DATA;

CREATE UNIQUE INDEX v_synthese_for_export_id_synthese_idx_tmp ON gn_synthese.v_synthese_for_export_tmp
USING btree (id_synthese);


\echo '----------------------------------------------------------------------------'
\echo 'Drop VIEW or MATERIALIZED VIEW gn_synthese.v_synthese_for_export if exists'

SELECT drop_any_type_of_view_if_exists('v_synthese_for_export');


\echo '----------------------------------------------------------------------------'
\echo 'Drop all other FINAL materialized views'

DROP MATERIALIZED VIEW IF EXISTS gn_synthese.synthese_status ;
DROP MATERIALIZED VIEW IF EXISTS taxonomie.taxon_area_status ;
DROP MATERIALIZED VIEW IF EXISTS gn_synthese.synthese_municipality ;


\echo '----------------------------------------------------------------------------'
\echo 'Rename all TMP materialized views'

ALTER MATERIALIZED VIEW gn_synthese.synthese_municipality_tmp RENAME
TO synthese_municipality ;
ALTER INDEX gn_synthese.synthese_municipality_id_synthese_idx_tmp RENAME
TO synthese_municipality_id_synthese_idx ;

ALTER MATERIALIZED VIEW taxonomie.taxon_area_status_tmp RENAME
TO taxon_area_status ;
ALTER INDEX taxonomie.taxon_area_status_cd_ref_id_area_idx_tmp RENAME
TO taxon_area_status_cd_ref_id_area_idx ;
ALTER INDEX taxonomie.taxon_area_status_status_idx_tmp RENAME
TO taxon_area_status_status_idx ;

ALTER MATERIALIZED VIEW gn_synthese.synthese_status_tmp RENAME
TO synthese_status ;
ALTER INDEX gn_synthese.synthese_status_id_synthese_idx_tmp RENAME
TO synthese_status_id_synthese_idx ;

ALTER MATERIALIZED VIEW gn_synthese.v_synthese_for_export_tmp RENAME
TO v_synthese_for_export ;
ALTER INDEX gn_synthese.v_synthese_for_export_id_synthese_idx_tmp RENAME
TO v_synthese_for_export_id_synthese_idx ;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
