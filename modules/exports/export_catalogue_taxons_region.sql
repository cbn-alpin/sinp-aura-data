-- Extract all distinct cd_ref for AURA region with cor_area_synthese

-- DROP TABLE gn_exports.v_catalog_taxa_region;

-- gn_exports.vm_catalog_taxa_region source

CREATE MATERIALIZED VIEW gn_exports.vm_catalog_taxa_region
AS
SELECT
	t.cd_ref,
	t.nom_valide,
	t.nom_vern AS nom_vernaculaire,
	count( s.id_synthese) filter (WHERE cas.id_area = 111614) AS nb_occurences_aura,
	max(s.date_max) filter (WHERE cas.id_area = 111614) AS derniere_obs_aura,
	count( s.id_synthese) filter (WHERE cas.id_area = 580366) AS nb_occurences_01,
	max(s.date_max) filter (WHERE cas.id_area = 580366) AS derniere_obs_01,
	count( s.id_synthese) filter (WHERE cas.id_area = 580370) AS nb_occurences_03,
	max(s.date_max) filter (WHERE cas.id_area = 580370) AS derniere_obs_03,
	count( s.id_synthese) filter (WHERE cas.id_area = 580365) AS nb_occurences_07,
	max(s.date_max) filter (WHERE cas.id_area = 580365) AS derniere_obs_07,
	count( s.id_synthese) filter (WHERE cas.id_area = 580372) AS nb_occurences_15,
	max(s.date_max) filter (WHERE cas.id_area = 580372) AS derniere_obs_15,
	count( s.id_synthese) filter (WHERE cas.id_area = 580375) AS nb_occurences_26,
	max(s.date_max) filter (WHERE cas.id_area = 580375) AS derniere_obs_26,
	count( s.id_synthese) filter (WHERE cas.id_area = 580374) AS nb_occurences_38,
	max(s.date_max) filter (WHERE cas.id_area = 580374) AS derniere_obs_38,
	count( s.id_synthese) filter (WHERE cas.id_area = 580376) AS nb_occurences_42,
	max(s.date_max) filter (WHERE cas.id_area = 580376) AS derniere_obs_42,
	count( s.id_synthese) filter (WHERE cas.id_area = 580373) AS nb_occurences_43,
	max(s.date_max) filter (WHERE cas.id_area = 580373) AS derniere_obs_43,
	count( s.id_synthese) filter (WHERE cas.id_area = 580367) AS nb_occurences_63,
	max(s.date_max) filter (WHERE cas.id_area = 580367) AS derniere_obs_63,
	count( s.id_synthese) filter (WHERE cas.id_area = 580369) AS nb_occurences_69,
	max(s.date_max) filter (WHERE cas.id_area = 580369) AS derniere_obs_69,
	count( s.id_synthese) filter (WHERE cas.id_area = 580371) AS nb_occurences_73,
	max(s.date_max) filter (WHERE cas.id_area = 580371) AS derniere_obs_73,
	count( s.id_synthese) filter (WHERE cas.id_area = 580368) AS nb_occurences_74,
	max(s.date_max) filter (WHERE cas.id_area = 580368) AS derniere_obs_74
FROM gn_synthese.synthese AS s
	JOIN gn_synthese.cor_area_synthese AS cas
		ON s.id_synthese = cas.id_synthese
 	JOIN taxonomie.taxref AS t
 		ON s.cd_nom = t.cd_nom
GROUP BY t.cd_ref, t.nom_valide, t.nom_vern
ORDER BY t.nom_valide ;
