-- PNR Pilat synthese export with geom blurred depending on sensitivity level

-- Enable timing
\timing

BEGIN;

\echo '----------------------------------------------------------------------------'
\echo 'Create materialized view gn_exports.pnr_pilat_blurred'

CREATE MATERIALIZED VIEW gn_exports.pnr_pilat_blurred AS
WITH
blurred_centroid AS (
	SELECT
		sb.id_synthese,
		st_centroid(st_union(sb.geom_4326)) AS geom_point
	FROM gn_exports.synthese_blurred AS sb
	GROUP BY sb.id_synthese
),

pnr_pilat AS(
	SELECT
		UNNEST(
			ARRAY['69091','69080','43227','42129','42308','69252','42280','42271','42246','42322','42115','42326','42327','42132','07056','07258','42207','07010','69235','42218','43204','42287','42067','07041','42028','42201','07344','42329','42023','43172','07347','42101','42272','07160','43223','43163','07143','42172','42124','42237','69236','42064','69064','69118','42085','42017','42286','69253','42053','42051','07333','42056','69097','69193','42018','42191','42167','42224','42265','42093','69007','42210','07044','42310','07342','42168','42044','07265','69119','42306','07310','69189','07243','43205','42139','07212']
			) AS code
),

synthese_export AS (
	SELECT
		DISTINCT s.id_synthese,
		s.the_geom_4326
	FROM gn_synthese.synthese s
		LEFT JOIN gn_synthese.cor_area_synthese cas
			ON s.id_synthese = cas.id_synthese
		LEFT JOIN ref_geo.l_areas a
			ON cas.id_area = a.id_area
		JOIN pnr_pilat p
			ON a.area_code = p.code
)
SELECT
    s.id_synthese,
    s.entity_source_pk_value                         AS id_source,
    s.unique_id_sinp                                 AS id_perm_sinp,
    s.unique_id_sinp_grp                             AS id_perm_grp_sinp,
    s.date_min::date                                 AS date_debut,
    s.date_max::date                                 AS date_fin,
    s.cd_nom,
    s.meta_v_taxref                                  AS version_taxref,
    s.nom_cite,
    s.count_min                                      AS nombre_min,
    s.count_max                                      AS nombre_max,
    s.altitude_min,
    s.altitude_max,
    s.depth_min                                      AS profondeur_min,
    s.depth_max                                      AS profondeur_max,
    s.observers                                      AS observateurs,
    s.determiner                                     AS determinateur,
    s.validator                                      AS validateur,
    s.comment_context                                AS comment_releve,
    s.comment_description                            AS comment_occurrence,
    td.dataset_shortname                             AS jdd_nom_court,
    td.unique_dataset_id                             AS jdd_uuid,
    s.reference_biblio,
    s.cd_hab                                         AS code_habitat,
    h.lb_hab_fr                                      AS habitat,
    s.place_name                                     AS nom_lieu,
    s.precision,
    s.additional_data                                AS donnees_additionnelles,
    CASE
        WHEN bc.geom_point IS NOT NULL
            THEN st_astext(bc.geom_point)
        ELSE st_astext(s.the_geom_point)
    END                                              AS the_geom_point,
    n1.cd_nomenclature                               AS nature_objet_geo,
    n2.cd_nomenclature                               AS type_regroupement,
    s.grp_method                                     AS methode_regroupement,
    n3.cd_nomenclature                               AS comportement,
    n4.cd_nomenclature                               AS technique_obs,
    n5.cd_nomenclature                               AS statut_biologique,
    n6.cd_nomenclature                               AS etat_biologique,
    n7.cd_nomenclature                               AS naturalite,
    n8.cd_nomenclature                               AS preuve_existante,
    n9.cd_nomenclature                               AS precision_diffusion,
    n10.cd_nomenclature                              AS stade_vie,
    n11.cd_nomenclature                              AS sexe,
    n12.cd_nomenclature                              AS objet_denombrement,
    n13.cd_nomenclature                              AS type_denombrement,
    n14.cd_nomenclature                              AS niveau_sensibilite,
    n15.cd_nomenclature                              AS statut_observation,
    n16.cd_nomenclature                              AS floutage_dee,
    n17.cd_nomenclature                              AS statut_source,
    n18.cd_nomenclature                              AS type_info_geo,
    n19.cd_nomenclature                              AS methode_determination,
    n20.cd_nomenclature                              AS statut_validation,
    coalesce(s.meta_update_date, s.meta_create_date) AS derniere_action
FROM gn_synthese.synthese AS s
    JOIN synthese_export se
        ON se.id_synthese = s.id_synthese
    JOIN gn_meta.t_datasets td
        ON td.id_dataset = s.id_dataset
    LEFT JOIN blurred_centroid AS bc
        ON bc.id_synthese = s.id_synthese
    LEFT JOIN ref_habitats.habref h
        ON h.cd_hab = s.cd_hab
    LEFT JOIN ref_nomenclatures.t_nomenclatures n1
        ON s.id_nomenclature_geo_object_nature = n1.id_nomenclature
    LEFT JOIN ref_nomenclatures.t_nomenclatures n2
        ON s.id_nomenclature_grp_typ = n2.id_nomenclature
    LEFT JOIN ref_nomenclatures.t_nomenclatures n3
        ON s.id_nomenclature_behaviour = n3.id_nomenclature
    LEFT JOIN ref_nomenclatures.t_nomenclatures n4
        ON s.id_nomenclature_obs_technique = n4.id_nomenclature
    LEFT JOIN ref_nomenclatures.t_nomenclatures n5
        ON s.id_nomenclature_bio_status = n5.id_nomenclature
    LEFT JOIN ref_nomenclatures.t_nomenclatures n6
        ON s.id_nomenclature_bio_condition = n6.id_nomenclature
    LEFT JOIN ref_nomenclatures.t_nomenclatures n7
        ON s.id_nomenclature_naturalness = n7.id_nomenclature
    LEFT JOIN ref_nomenclatures.t_nomenclatures n8
        ON s.id_nomenclature_exist_proof = n8.id_nomenclature
    LEFT JOIN ref_nomenclatures.t_nomenclatures n9
        ON s.id_nomenclature_diffusion_level = n9.id_nomenclature
    LEFT JOIN ref_nomenclatures.t_nomenclatures n10
        ON s.id_nomenclature_life_stage = n10.id_nomenclature
    LEFT JOIN ref_nomenclatures.t_nomenclatures n11
        ON s.id_nomenclature_sex = n11.id_nomenclature
    LEFT JOIN ref_nomenclatures.t_nomenclatures n12
        ON s.id_nomenclature_obj_count = n12.id_nomenclature
    LEFT JOIN ref_nomenclatures.t_nomenclatures n13
        ON s.id_nomenclature_type_count = n13.id_nomenclature
    LEFT JOIN ref_nomenclatures.t_nomenclatures n14
        ON s.id_nomenclature_sensitivity = n14.id_nomenclature
    LEFT JOIN ref_nomenclatures.t_nomenclatures n15
        ON s.id_nomenclature_observation_status = n15.id_nomenclature
    LEFT JOIN ref_nomenclatures.t_nomenclatures n16
        ON s.id_nomenclature_blurring = n16.id_nomenclature
    LEFT JOIN ref_nomenclatures.t_nomenclatures n17
        ON s.id_nomenclature_source_status = n17.id_nomenclature
    LEFT JOIN ref_nomenclatures.t_nomenclatures n18
        ON s.id_nomenclature_info_geo_type = n18.id_nomenclature
    LEFT JOIN ref_nomenclatures.t_nomenclatures n19
        ON s.id_nomenclature_determination_method = n19.id_nomenclature
    LEFT JOIN ref_nomenclatures.t_nomenclatures n20
        ON s.id_nomenclature_valid_status = n20.id_nomenclature
WHERE
    s.the_geom_point IS NOT NULL
    AND n15.cd_nomenclature = 'Pr'
    AND n9.cd_nomenclature != '4'
    AND n14.cd_nomenclature NOT IN ('4', '2.8')
;

CREATE UNIQUE INDEX unique_idx_pnr_pilat_blurred ON gn_exports.pnr_pilat_blurred (id_synthese);

\echo '----------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
