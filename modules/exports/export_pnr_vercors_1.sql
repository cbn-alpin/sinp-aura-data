-- PNR Vercors synthese export with precise geom < 2017 (1)

-- Enable timing
\timing

BEGIN;

\echo '----------------------------------------------------------------------------'
\echo 'Create materialized view gn_exports.pnr_vercors_1'

CREATE MATERIALIZED VIEW gn_exports.pnr_vercors_1 AS
WITH
pnr_vercors AS (
    SELECT
        UNNEST(
            ARRAY['26081','26382','26232','26100','26023','38409','38322','38356','38092','38108',
            '38018','26149','26381','26273','26039','38453','38036','38333','38195','26034',
            '26224','38319','38443','26032','26024','26212','38436','38524','38235','38111',
            '38187','38338','38390','38117','38216','38345','38248','38450','38474','38281',
            '38169','38485','38540','38486','26086','26142','26354','26168','26055','26098',
            '26365','26299','26291','26327','26364','26371','26059','26066','26163','26069',
            '26035','26240','26246','26128','26141','26175','26346','26159','26290','26001',
            '26195','26282','26308','26221','26316','26113','38186','38103','38429','26359',
            '26270','26309','26074','26320','26117','26307','26217','26315','26223','26311',
            '26331','26302','38355','38129','38205','38548','38225','38090','38391','38243',
            '38419','38113','38204','38424','38301','38438','38153','38433']
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
        JOIN pnr_vercors AS p
            ON a.area_code = p.code
    WHERE s.date_min < '2017-01-01'
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
    n1.cd_nomenclature AS nature_objet_geo,
    n2.cd_nomenclature AS type_regroupement,
    s.grp_method AS methode_regroupement,
    n3.cd_nomenclature AS comportement,
    n4.cd_nomenclature AS technique_obs,
    n5.cd_nomenclature AS statut_biologique,
    n6.cd_nomenclature AS etat_biologique,
    n7.cd_nomenclature AS naturalite,
    n8.cd_nomenclature AS preuve_existante,
    n9.cd_nomenclature AS precision_diffusion,
    n10.cd_nomenclature AS stade_vie,
    n11.cd_nomenclature AS sexe,
    n12.cd_nomenclature AS objet_denombrement,
    n13.cd_nomenclature AS type_denombrement,
    n14.cd_nomenclature AS niveau_sensibilite,
    n15.cd_nomenclature AS statut_observation,
    n16.cd_nomenclature AS floutage_dee,
    n17.cd_nomenclature AS statut_source,
    n18.cd_nomenclature AS type_info_geo,
    n19.cd_nomenclature AS methode_determination,
    n20.cd_nomenclature AS statut_validation,
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

CREATE UNIQUE INDEX unique_idx_pnr_vercors_1
ON gn_exports.pnr_vercors_1 (id_synthese) ;

\echo '----------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
