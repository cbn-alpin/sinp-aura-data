-- PNR Haut Jura synthese export with geom blurred depending on sensitivity level

-- Enable timing
\timing

BEGIN;

\echo '----------------------------------------------------------------------------'
\echo 'Create materialized view gn_exports.pnr_haut_jura_blurred'

CREATE MATERIALIZED VIEW gn_exports.pnr_haut_jura_blurred AS
WITH
blurred_centroid AS (
	SELECT
		sb.id_synthese,
		st_centroid(st_union(sb.geom_4326)) AS geom_point
	FROM gn_exports.synthese_blurred AS sb
	GROUP BY sb.id_synthese
),

pnr_haut_jura AS(
	SELECT
		UNNEST(
			ARRAY['01187','01288','01240','01360','01104','01095','01392','01125','01033','01078','01171','01035','01436','01180','01397','01011','01354','01247','01257','01209','01174','01357','01204','01081','01158','01308','01114','01109','01210','01281','01143','01160','01135','01401','01435','01103','01071','01399','01313','01153','01087','01283','01148','01014','01173','01031','01419','01298','01274','01269','01152']
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
		JOIN pnr_haut_jura p
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

CREATE UNIQUE INDEX unique_idx_pnr_haut_jura_blurred ON gn_exports.pnr_haut_jura_blurred (id_synthese);

\echo '----------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;

