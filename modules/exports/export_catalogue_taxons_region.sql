-- Extract all distinct cd_ref for AURA region with cor_area_synthese
-- DROP TABLE gn_exports.v_catalog_taxa_region;

-- gn_exports.v_catalog_taxa_region source

CREATE OR REPLACE VIEW gn_exports.v_catalog_taxa_region
AS
SELECT DISTINCT
	t.cd_ref,
	t.nom_valide,
	t.nom_vern AS nom_vernaculaire,
	count(DISTINCT s.id_synthese) AS nb_occurences_aura,
	max(s.date_max) AS derniere_obs_aura,
	count(DISTINCT s.id_synthese) filter (WHERE bat.type_code = 'DEP' AND la.area_code = '01') AS nb_occurences_01,
	max(s.date_max) filter (WHERE bat.type_code = 'DEP' AND la.area_code = '01') AS derniere_obs_01,
	count(DISTINCT s.id_synthese) filter (WHERE bat.type_code = 'DEP' AND la.area_code = '03') AS nb_occurences_03,
	max(s.date_max) filter (WHERE bat.type_code = 'DEP' AND la.area_code = '03') AS derniere_obs_03,
	count(DISTINCT s.id_synthese) filter (WHERE bat.type_code = 'DEP' AND la.area_code = '07') AS nb_occurences_07,
	max(s.date_max) filter (WHERE bat.type_code = 'DEP' AND la.area_code = '07') AS derniere_obs_07,
	count(DISTINCT s.id_synthese) filter (WHERE bat.type_code = 'DEP' AND la.area_code = '15') AS nb_occurences_15,
	max(s.date_max) filter (WHERE bat.type_code = 'DEP' AND la.area_code = '15') AS derniere_obs_15,
	count(DISTINCT s.id_synthese) filter (WHERE bat.type_code = 'DEP' AND la.area_code = '26') AS nb_occurences_26,
	max(s.date_max) filter (WHERE bat.type_code = 'DEP' AND la.area_code = '26') AS derniere_obs_26,
	count(DISTINCT s.id_synthese) filter (WHERE bat.type_code = 'DEP' AND la.area_code = '38') AS nb_occurences_38,
	max(s.date_max) filter (WHERE bat.type_code = 'DEP' AND la.area_code = '38') AS derniere_obs_38,
	count(DISTINCT s.id_synthese) filter (WHERE bat.type_code = 'DEP' AND la.area_code = '42') AS nb_occurences_42,
	max(s.date_max) filter (WHERE bat.type_code = 'DEP' AND la.area_code = '42') AS derniere_obs_42,
	count(DISTINCT s.id_synthese) filter (WHERE bat.type_code = 'DEP' AND la.area_code = '43') AS nb_occurences_43,
	max(s.date_max) filter (WHERE bat.type_code = 'DEP' AND la.area_code = '43') AS derniere_obs_43,
	count(DISTINCT s.id_synthese) filter (WHERE bat.type_code = 'DEP' AND la.area_code = '63') AS nb_occurences_63,
	max(s.date_max) filter (WHERE bat.type_code = 'DEP' AND la.area_code = '63') AS derniere_obs_63,
	count(DISTINCT s.id_synthese) filter (WHERE bat.type_code = 'DEP' AND la.area_code = '69') AS nb_occurences_69,
	max(s.date_max) filter (WHERE bat.type_code = 'DEP' AND la.area_code = '69') AS derniere_obs_69,
	count(DISTINCT s.id_synthese) filter (WHERE bat.type_code = 'DEP' AND la.area_code = '73') AS nb_occurences_73,
	max(s.date_max) filter (WHERE bat.type_code = 'DEP' AND la.area_code = '73') AS derniere_obs_73,
	count(DISTINCT s.id_synthese) filter (WHERE bat.type_code = 'DEP' AND la.area_code = '74') AS nb_occurences_74,
	max(s.date_max) filter (WHERE bat.type_code = 'DEP' AND la.area_code = '74') AS derniere_obs_74
FROM gn_synthese.synthese AS s
	JOIN gn_synthese.cor_area_synthese AS cas
		ON s.id_synthese = cas.id_synthese
	JOIN ref_geo.l_areas AS la
		ON la.id_area = cas.id_area
	JOIN ref_geo.bib_areas_types AS bat
		ON bat.id_type = la.id_type
 	JOIN taxonomie.taxref AS t
 		ON s.cd_nom = t.cd_nom
GROUP BY t.cd_ref, t.nom_valide, t.nom_vern
ORDER BY t.nom_valide ;

