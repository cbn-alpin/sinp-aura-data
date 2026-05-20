-- PNR Baronnies provençales synthese export with precise geom

-- Enable timing
\timing

BEGIN;

\echo '----------------------------------------------------------------------------'
\echo 'Drop materialized view if exists gn_exports.pnr_baronnies_provencales'
DROP MATERIALIZED VIEW IF EXISTS gn_exports.pnr_baronnies_provencales;

\echo '----------------------------------------------------------------------------'
\echo 'Create materialized view gn_exports.pnr_baronnies_provencales'

CREATE MATERIALIZED VIEW gn_exports.pnr_baronnies_provencales AS
WITH
    pnr_baronnies_provencales AS (
        SELECT
            UNNEST(
                    ARRAY['26012','26013','26016','26018','26022','26026','26043','26046','26048','26050','26063','26067',
                    '26075','26082','26089','26091','26103','26104','26105','26112','26126','26127','26130','26135','26150',
                    '26153','26154','26161','26180','26181','26182','26188','26189','26190','26192','26193','26199','26200',
                    '26201','26202','26209','26215','26220','26226','26227','26229','26233','26236','26238','26239','26242',
                    '26244','26245','26256','26263','26264','26267','26269','26276','26278','26279','26283','26285','26286',
                    '26288','26292','26303','26304','26306','26317','26318','26322','26329','26335','26340','26348','26350',
                    '26363','26367','26369','26370','26372','26373','26374','26375','26376','26377']
            ) AS code
    ),
    synthese_export AS (
        SELECT DISTINCT
            s.id_synthese,
            s.the_geom_4326
        FROM gn_synthese.synthese AS s
                 LEFT JOIN gn_synthese.cor_area_synthese AS cas
                           ON s.id_synthese = cas.id_synthese
                 LEFT JOIN ref_geo.l_areas AS a
                           ON cas.id_area = a.id_area
                 JOIN pnr_baronnies_provencales AS p
                      ON a.area_code = p.code
    )
SELECT
    s.id_synthese,
    s.entity_source_pk_value AS id_source,
    s.unique_id_sinp AS id_perm_sinp,
    s.unique_id_sinp_grp AS id_perm_grp_sinp,
    s.date_min::date AS date_debut,
    s.date_max::date AS date_fin,
    s.cd_nom,
    s.meta_v_taxref AS version_taxref,
    s.nom_cite,
    s.count_min AS nombre_min,
    s.count_max AS nombre_max,
    s.altitude_min,
    s.altitude_max,
    s.depth_min AS profondeur_min,
    s.depth_max AS profondeur_max,
    s.observers AS observateurs,
    s.determiner AS determinateur,
    s.validator AS validateur,
    s.comment_context AS comment_releve,
    s.comment_description AS comment_occurrence,
    td.dataset_shortname AS jdd_nom_court,
    td.unique_dataset_id AS jdd_uuid,
    ta.acquisition_framework_name AS ca_name,
    ta.unique_acquisition_framework_id AS ca_uuid,
    s.reference_biblio,
    s.cd_hab AS code_habitat,
    h.lb_hab_fr AS habitat,
    s.place_name AS nom_lieu,
    s.precision,
    s.additional_data AS donnees_additionnelles,
    st_astext(s.the_geom_4326) AS wkt_4326,
    n1.label_default AS nature_objet_geo,
    n2.label_default AS type_regroupement,
    s.grp_method AS methode_regroupement,
    n3.label_default AS comportement,
    n4.label_default AS technique_obs,
    n5.label_default AS statut_biologique,
    n6.label_default AS etat_biologique,
    n7.label_default AS naturalite,
    n8.label_default AS preuve_existante,
    n9.label_default AS precision_diffusion,
    n10.label_default AS stade_vie,
    n11.label_default AS sexe,
    n12.label_default AS objet_denombrement,
    n13.label_default AS type_denombrement,
    n14.label_default AS niveau_sensibilite,
    n15.label_default AS statut_observation,
    n16.label_default AS floutage_dee,
    n17.label_default AS statut_source,
    n18.label_default AS type_info_geo,
    n19.label_default AS methode_determination,
    n20.label_default AS statut_validation,
    CASE
        WHEN n14.cd_nomenclature > '0' THEN
            'donnée sensible'
        ELSE 'donnée non sensible'
        END
        AS sensibilite,
    coalesce(s.meta_update_date, s.meta_create_date) AS derniere_action
FROM gn_synthese.synthese AS s
         JOIN synthese_export AS se
              ON se.id_synthese = s.id_synthese
         JOIN gn_meta.t_datasets AS td
              ON td.id_dataset = s.id_dataset
         JOIN gn_meta.t_acquisition_frameworks AS ta
              ON ta.id_acquisition_framework = td.id_acquisition_framework
         LEFT JOIN ref_habitats.habref AS h
                   ON h.cd_hab = s.cd_hab
         LEFT JOIN ref_nomenclatures.t_nomenclatures AS n1
                   ON s.id_nomenclature_geo_object_nature = n1.id_nomenclature
         LEFT JOIN ref_nomenclatures.t_nomenclatures AS n2
                   ON s.id_nomenclature_grp_typ = n2.id_nomenclature
         LEFT JOIN ref_nomenclatures.t_nomenclatures AS n3
                   ON s.id_nomenclature_behaviour = n3.id_nomenclature
         LEFT JOIN ref_nomenclatures.t_nomenclatures AS n4
                   ON s.id_nomenclature_obs_technique = n4.id_nomenclature
         LEFT JOIN ref_nomenclatures.t_nomenclatures AS n5
                   ON s.id_nomenclature_bio_status = n5.id_nomenclature
         LEFT JOIN ref_nomenclatures.t_nomenclatures AS n6
                   ON s.id_nomenclature_bio_condition = n6.id_nomenclature
         LEFT JOIN ref_nomenclatures.t_nomenclatures AS n7
                   ON s.id_nomenclature_naturalness = n7.id_nomenclature
         LEFT JOIN ref_nomenclatures.t_nomenclatures AS n8
                   ON s.id_nomenclature_exist_proof = n8.id_nomenclature
         LEFT JOIN ref_nomenclatures.t_nomenclatures AS n9
                   ON s.id_nomenclature_diffusion_level = n9.id_nomenclature
         LEFT JOIN ref_nomenclatures.t_nomenclatures AS n10
                   ON s.id_nomenclature_life_stage = n10.id_nomenclature
         LEFT JOIN ref_nomenclatures.t_nomenclatures AS n11
                   ON s.id_nomenclature_sex = n11.id_nomenclature
         LEFT JOIN ref_nomenclatures.t_nomenclatures AS n12
                   ON s.id_nomenclature_obj_count = n12.id_nomenclature
         LEFT JOIN ref_nomenclatures.t_nomenclatures AS n13
                   ON s.id_nomenclature_type_count = n13.id_nomenclature
         LEFT JOIN ref_nomenclatures.t_nomenclatures AS n14
                   ON s.id_nomenclature_sensitivity = n14.id_nomenclature
         LEFT JOIN ref_nomenclatures.t_nomenclatures AS n15
                   ON s.id_nomenclature_observation_status = n15.id_nomenclature
         LEFT JOIN ref_nomenclatures.t_nomenclatures AS n16
                   ON s.id_nomenclature_blurring = n16.id_nomenclature
         LEFT JOIN ref_nomenclatures.t_nomenclatures AS n17
                   ON s.id_nomenclature_source_status = n17.id_nomenclature
         LEFT JOIN ref_nomenclatures.t_nomenclatures AS n18
                   ON s.id_nomenclature_info_geo_type = n18.id_nomenclature
         LEFT JOIN ref_nomenclatures.t_nomenclatures AS n19
                   ON s.id_nomenclature_determination_method = n19.id_nomenclature
         LEFT JOIN ref_nomenclatures.t_nomenclatures AS n20
                   ON s.id_nomenclature_valid_status = n20.id_nomenclature
WHERE s.the_geom_4326 IS NOT NULL
  AND n15.cd_nomenclature = 'Pr' -- Présence
  AND n9.cd_nomenclature != '4' -- Aucune diffusion
  AND n14.cd_nomenclature NOT IN ('4', '2.8') -- Aucune diffusion
;

CREATE UNIQUE INDEX unique_idx_pnr_baronnies_provencales
    ON gn_exports.pnr_baronnies_provencales (id_synthese) ;

\echo '----------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;