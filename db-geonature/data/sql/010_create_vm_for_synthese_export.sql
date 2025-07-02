
-- Create materialized views to enhance synthese export view
-- Required rights: DB OWNER
-- Transfert this script on server this way:
-- rsync -av ./010_* geonat@db-aura-sinp:~/data/db-geonature/data/sql/ --dry-run
-- Use this script this way: psql -h localhost -U geonatadmin -d geonature2db -f ~/data/db-geonature/data/sql/010_*

BEGIN;


\echo '----------------------------------------------------------------------------'
\echo 'Create MATERIALIZED VIEW gn_synthese.synthese_municipality'

DROP MATERIALIZED VIEW IF EXISTS gn_synthese.synthese_municipality ;

CREATE MATERIALIZED VIEW gn_synthese.synthese_municipality
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

-- View indexes:
CREATE INDEX synthese_municipality_id_synthese_idx ON gn_synthese.synthese_municipality
USING btree (id_synthese);


\echo '----------------------------------------------------------------------------'
\echo 'Create MATERIALIZED VIEW taxonomie.taxon_area_status'

DROP MATERIALIZED VIEW IF EXISTS taxonomie.taxon_area_status ;

CREATE MATERIALIZED VIEW taxonomie.taxon_area_status
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

-- View indexes:
CREATE INDEX taxon_area_status_cd_ref_id_area_idx ON taxonomie.taxon_area_status
USING btree (cd_ref, id_area);
CREATE INDEX taxon_area_status_status_idx ON taxonomie.taxon_area_status
USING gin (status);


\echo '----------------------------------------------------------------------------'
\echo 'Create MATERIALIZED VIEW gn_synthese.synthese_status'

DROP MATERIALIZED VIEW IF EXISTS gn_synthese.synthese_status ;

CREATE MATERIALIZED VIEW gn_synthese.synthese_status
TABLESPACE pg_default AS
  SELECT
    s.id_synthese,
    tas.status -> 'PN'::text AS status_pn,
    tas.status -> 'PR'::text AS status_pr,
    tas.status -> 'PD'::text AS status_pd,
    tas.status -> 'LRM'::text AS status_lrm,
    tas.status -> 'LRE'::text AS status_lre,
    tas.status -> 'LRN'::text AS status_lrn,
    tas.status -> 'LRR'::text AS status_lrr,
    tas.status -> 'LRD'::text AS status_lrd
  FROM gn_synthese.synthese AS s
    LEFT JOIN taxonomie.taxref AS t
      ON t.cd_nom = s.cd_nom
    LEFT JOIN gn_synthese.cor_area_synthese AS cas
      ON s.id_synthese = cas.id_synthese
    JOIN taxonomie.taxon_area_status AS tas
      ON cas.id_area = tas.id_area AND t.cd_ref = tas.cd_ref
WITH DATA;

-- View indexes:
CREATE INDEX synthese_status_id_synthese_idx ON gn_synthese.synthese_status
USING btree (id_synthese);


\echo '----------------------------------------------------------------------------'
\echo 'Create MATERIALIZED VIEW gn_synthese.v_synthese_for_export_tmp'

DROP MATERIALIZED VIEW IF EXISTS gn_synthese.v_synthese_for_export_tmp ;

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
    s.additional_data ->> 'precisionLabel'::text AS type_precision,
    CASE
      WHEN ns.cd_nomenclature::text = '0'::text THEN 'donnée non sensible'::text
      WHEN s.id_nomenclature_sensitivity IS NULL THEN ''::text
      ELSE 'donnée sensible'::text
    END AS sensibilite,
    CASE
      WHEN ns.cd_nomenclature::text <> '0'::text OR dl.cd_nomenclature::text <> '5'::text
        THEN 'donnée confidentielle'::text
      ELSE 'donnée non confidentielle'::text
    END AS confidentialite,
    COALESCE(nb.cd_nomenclature, 'NON'::character varying) AS floutage,
    sd.id_dataset AS jdd_id,
    s.id_digitiser,
    st_asgeojson(s.the_geom_local) AS geojson_local,
    s.id_nomenclature_sensitivity,
    s.id_nomenclature_diffusion_level,
    ss.status_pn,
    ss.status_pr,
    ss.status_pd,
    ss.status_lrm,
    ss.status_lre,
    ss.status_lrn,
    ss.status_lrr,
    ss.status_lrd
  FROM gn_synthese.synthese AS s
    JOIN taxonomie.taxref AS t
      ON t.cd_nom = s.cd_nom
    LEFT JOIN gn_synthese.synthese_municipality AS sm
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
                  'ROLE_ACTEUR'::character varying,
                  '5'::character varying
                )
                OR cad.id_nomenclature_actor_role = ref_nomenclatures.get_id_nomenclature(
                  'ROLE_ACTEUR'::character varying,
                  '6'::character varying
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
    LEFT JOIN gn_synthese.synthese_status AS ss
      ON s.id_synthese = ss.id_synthese
    LEFT JOIN ref_nomenclatures.t_nomenclatures AS nb
      ON s.id_nomenclature_blurring = nb.id_nomenclature;
WITH DATA;

-- View indexes:
CREATE INDEX v_synthese_for_export_id_synthese_idx ON gn_synthese.v_synthese_for_export_tmp
USING btree (id_synthese);


\echo '----------------------------------------------------------------------------'
\echo 'Drop VIEW gn_synthese.v_synthese_for_export'

DROP VIEW IF EXISTS gn_synthese.v_synthese_for_export;


\echo '----------------------------------------------------------------------------'
\echo 'Rename VIEW gn_synthese.v_synthese_for_export_tmp to gn_synthese.v_synthese_for_export'

ALTER MATERIALIZED VIEW gn_synthese.v_synthese_for_export_tmp RENAME TO v_synthese_for_export;


\echo '----------------------------------------------------------------------------'
COMMIT;
