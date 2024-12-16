-- Extract all distinct cd_ref for AURA region with cor_area_synthese

BEGIN;

CREATE OR REPLACE FUNCTION ref_geo.get_id_area_by_code(typeCode varchar, areaCode varchar)
 RETURNS integer
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
    -- Function which return the id_area from l_areas
    DECLARE idArea integer;

    BEGIN
        SELECT INTO idArea id_area
        FROM ref_geo.l_areas AS la
		JOIN ref_geo.bib_areas_types AS bat
			ON bat.id_type = la.id_type
        WHERE bat.type_code = typeCode
			AND la.area_code = areaCode ;

        RETURN idArea ;
    END;
$function$
;


CREATE MATERIALIZED VIEW gn_exports.catalog_taxa_region
AS
SELECT
	t.cd_ref,
	t.nom_valide,
	t.nom_vern AS nom_vernaculaire,
	count( s.id_synthese) filter (WHERE cas.id_area = ref_geo.get_id_area_by_code('REG','00084')) AS nb_occurences_aura,
	max(s.date_max) filter (WHERE cas.id_area = ref_geo.get_id_area_by_code('REG','00084')) AS derniere_obs_aura,
	count( s.id_synthese) filter (WHERE cas.id_area = ref_geo.get_id_area_by_code('DEP','01')) AS nb_occurences_01,
	max(s.date_max) filter (WHERE cas.id_area = ref_geo.get_id_area_by_code('DEP','01')) AS derniere_obs_01,
	count( s.id_synthese) filter (WHERE cas.id_area = ref_geo.get_id_area_by_code('DEP','03')) AS nb_occurences_03,
	max(s.date_max) filter (WHERE cas.id_area = ref_geo.get_id_area_by_code('DEP','03')) AS derniere_obs_03,
	count( s.id_synthese) filter (WHERE cas.id_area = ref_geo.get_id_area_by_code('DEP','07')) AS nb_occurences_07,
	max(s.date_max) filter (WHERE cas.id_area = ref_geo.get_id_area_by_code('DEP','07')) AS derniere_obs_07,
	count( s.id_synthese) filter (WHERE cas.id_area = ref_geo.get_id_area_by_code('DEP','15')) AS nb_occurences_15,
	max(s.date_max) filter (WHERE cas.id_area = ref_geo.get_id_area_by_code('DEP','15')) AS derniere_obs_15,
	count( s.id_synthese) filter (WHERE cas.id_area = ref_geo.get_id_area_by_code('DEP','26')) AS nb_occurences_26,
	max(s.date_max) filter (WHERE cas.id_area = ref_geo.get_id_area_by_code('DEP','26')) AS derniere_obs_26,
	count( s.id_synthese) filter (WHERE cas.id_area = ref_geo.get_id_area_by_code('DEP','38')) AS nb_occurences_38,
	max(s.date_max) filter (WHERE cas.id_area = ref_geo.get_id_area_by_code('DEP','38')) AS derniere_obs_38,
	count( s.id_synthese) filter (WHERE cas.id_area = ref_geo.get_id_area_by_code('DEP','42')) AS nb_occurences_42,
	max(s.date_max) filter (WHERE cas.id_area = ref_geo.get_id_area_by_code('DEP','42')) AS derniere_obs_42,
	count( s.id_synthese) filter (WHERE cas.id_area = ref_geo.get_id_area_by_code('DEP','43')) AS nb_occurences_43,
	max(s.date_max) filter (WHERE cas.id_area = ref_geo.get_id_area_by_code('DEP','43')) AS derniere_obs_43,
	count( s.id_synthese) filter (WHERE cas.id_area = ref_geo.get_id_area_by_code('DEP','63')) AS nb_occurences_63,
	max(s.date_max) filter (WHERE cas.id_area = ref_geo.get_id_area_by_code('DEP','63')) AS derniere_obs_63,
	count( s.id_synthese) filter (WHERE cas.id_area = ref_geo.get_id_area_by_code('DEP','69')) AS nb_occurences_69,
	max(s.date_max) filter (WHERE cas.id_area = ref_geo.get_id_area_by_code('DEP','69')) AS derniere_obs_69,
	count( s.id_synthese) filter (WHERE cas.id_area = ref_geo.get_id_area_by_code('DEP','73')) AS nb_occurences_73,
	max(s.date_max) filter (WHERE cas.id_area = ref_geo.get_id_area_by_code('DEP','73')) AS derniere_obs_73,
	count( s.id_synthese) filter (WHERE cas.id_area = ref_geo.get_id_area_by_code('DEP','74')) AS nb_occurences_74,
	max(s.date_max) filter (WHERE cas.id_area = ref_geo.get_id_area_by_code('DEP','74')) AS derniere_obs_74
FROM gn_synthese.synthese AS s
	JOIN gn_synthese.cor_area_synthese AS cas
		ON s.id_synthese = cas.id_synthese
 	JOIN taxonomie.taxref AS t
 		ON s.cd_nom = t.cd_nom
GROUP BY t.cd_ref, t.nom_valide, t.nom_vern
ORDER BY t.nom_valide ;

COMMIT;
