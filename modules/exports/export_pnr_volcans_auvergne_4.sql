-- PNR des volcans d'Auvergne synthese export with precise geom >= 2020 (3)

-- Enable timing
\timing

BEGIN;

\echo '----------------------------------------------------------------------------'
\echo 'Drop materialized view if exists gn_exports.pnr_volcans_auvergne_4'
DROP MATERIALIZED VIEW IF EXISTS gn_exports.pnr_volcans_auvergne_4;

\echo '----------------------------------------------------------------------------'
\echo 'Create materialized view gn_exports.pnr_volcans_auvergne_4'

CREATE MATERIALIZED VIEW gn_exports.pnr_volcans_auvergne_4 AS
WITH
pnr_volcans_auvergne AS (
    SELECT
        UNNEST(
             ARRAY['15001','15002','15004','15006','15008','15009','15012','15014','15015','15019',
                '15020','15025','15026','15031','15033','15035','15037','15038','15040','15041',
                '15043','15047','15049','15050','15052','15053','15054','15055','15059','15061',
                '15066','15067','15069','15070','15074','15075','15077','15079','15080','15081',
                '15086','15091','15092','15095','15096','15098','15100','15101','15102','15105',
                '15110','15111','15112','15113','15114','15116','15123','15124','15126','15127',
                '15128','15129','15131','15132','15137','15138','15139','15141','15142','15146',
                '15148','15149','15151','15152','15154','15155','15161','15162','15164','15169',
                '15170','15171','15173','15174','15176','15178','15180','15185','15187','15190',
                '15192','15201','15202','15205','15206','15208','15213','15215','15218','15219',
                '15223','15225','15231','15232','15235','15236','15238','15240','15243','15244',
                '15246','15247','15248','15249','15250','15252','15253','15254','15255','15256',
                '15258','15261','15262','15263','15265','15266','43014','43247','63005','63006',
                '63007','63009','63017','63020','63024','63026','63028','63038','63042','63046',
                '63047','63048','63053','63070','63071','63074','63075','63077','63080','63083',
                '63084','63087','63092','63093','63097','63098','63103','63109','63111','63114',
                '63117','63122','63123','63126','63129','63134','63141','63144','63153','63159',
                '63165','63169','63172','63183','63189','63190','63191','63192','63198','63199',
                '63202','63209','63219','63220','63222','63225','63234','63236','63242','63246',
                '63247','63248','63250','63254','63257','63259','63263','63264','63274','63279',
                '63282','63285','63290','63299','63302','63303','63305','63308','63313','63315',
                '63326','63335','63336','63342','63345','63346','63351','63356','63357','63370',
                '63380','63381','63383','63385','63386','63395','63396','63397','63399','63401',
                '63403','63407','63409','63416','63417','63421','63422','63426','63429','63435',
                '63437','63440','63449','63450','63451','63452','63456','63458','63466','63470',
                '15145','63316','15115','15099','63330','15210','15044','15227']
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
        JOIN pnr_volcans_auvergne AS p
            ON a.area_code = p.code
    WHERE s.date_min >= '2020-01-01'
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

CREATE UNIQUE INDEX unique_idx_pnr_volcans_auvergne_4
ON gn_exports.pnr_volcans_auvergne_4 (id_synthese) ;

\echo '----------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
