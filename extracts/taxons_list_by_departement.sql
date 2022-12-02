-- Extract all distinct cd_nom for one departement with cor_area_synthese
-- Fastest
SELECT DISTINCT s.cd_nom, t.nom_complet, t.cd_ref, t.nom_valide, t.regne
FROM gn_synthese.synthese AS s
	JOIN gn_synthese.cor_area_synthese AS cas
		ON s.id_synthese = cas.id_synthese
	JOIN ref_geo.l_areas AS la
		ON la.id_area = cas.id_area
	JOIN ref_geo.bib_areas_types AS bat
		ON bat.id_type = la.id_type
 	JOIN taxonomie.taxref AS t
 		ON s.cd_nom = t.cd_nom
WHERE bat.type_code = 'DEP' AND la.area_code = '38'
ORDER BY t.nom_valide ;


-- Extract all distinct cd_nom for one departement with geometry function
-- Slowly
WITH dep_area AS (
	SELECT id_type
	FROM ref_geo.bib_areas_types
	WHERE type_code = 'DEP'
)
SELECT DISTINCT s.cd_nom, t.nom_complet, t.cd_ref, t.nom_valide, t.regne
FROM gn_synthese.synthese AS s
	JOIN ref_geo.l_areas AS l
		ON st_within(st_transform(s.the_geom_point, 2154), l.geom)
 	JOIN taxonomie.taxref AS t
 		ON s.cd_nom = t.cd_nom
WHERE l.area_code = '38' AND l.id_type = (SELECT id_type FROM dep_area)
ORDER BY t.nom_valide ;
