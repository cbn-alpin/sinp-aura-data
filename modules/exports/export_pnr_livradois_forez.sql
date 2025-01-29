-- PNR Livradois Forez synthese export with geom blurred depending on sensitivity level

-- Enable timing
\timing

BEGIN;

\echo '----------------------------------------------------------------------------'
\echo 'Create materialized view gn_exports.pnr_livradois_forez_blurred'

CREATE MATERIALIZED VIEW gn_exports.pnr_livradois_forez_blurred AS
WITH
blurred_centroid AS (
	SELECT
		sb.id_synthese,
		st_centroid(st_union(sb.geom_4326)) AS geom_point
	FROM gn_exports.synthese_blurred AS sb
	GROUP BY sb.id_synthese
),

pnr_livradois_forez AS(
	SELECT
		UNNEST(
			ARRAY['03125','03141','42034','42039','42040','42045','42121','42159','42188','42205','42276','42295','42298','42339','43003','43016','43023','43027','43035','43048','43052','43055','43057','43059','43063','43064','43067','43071','43073','43075','43076','43080','43093','43100','43105','43106','43107','43108','43116','43117','43128','43131','43138','43139','43178','43183','43189','43193','43196','43201','43208','43214','43219','43226','43228','43237','43250','43252','63002','63003','63008','63010','63015','63016','63023','63027','63029','63037','63039','63040','63044','63045','63056','63057','63058','63065','63066','63072','63076','63079','63081','63086','63088','63095','63102','63104','63105','63119','63125','63128','63132','63136','63137','63138','63139','63142','63145','63146','63147','63151','63155','63156','63157','63158','63161','63162','63168','63173','63174','63177','63179','63184','63196','63205','63207','63211','63216','63218','63221','63230','63231','63239','63249','63252','63253','63256','63258','63260','63265','63267','63271','63276','63277','63280','63291','63297','63298','63301','63309','63310','63312','63314','63319','63323','63324','63328','63331','63334','63337','63340','63341','63343','63348','63353','63355','63364','63365','63366','63367','63368','63371','63374','63376','63378','63384','63389','63393','63394','63398','63402','63405','63412','63414','63415','63418','63423','63430','63431','63434','63438','63439','63441','63442','63448','63454','63457','63461','63463','63465','63468','63469']
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
		JOIN pnr_livradois_forez p
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

\echo '----------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
