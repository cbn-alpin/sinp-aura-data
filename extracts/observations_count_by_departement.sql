-- Count observation by departement with cor_area_synthese
SELECT
    la.area_code,
    la.area_name,
    COUNT(s.id_synthese) AS obs_nbre
FROM gn_synthese.synthese AS s
    JOIN gn_synthese.cor_area_synthese AS cas
        ON s.id_synthese = cas.id_synthese
    JOIN ref_geo.l_areas AS la
        ON la.id_area = cas.id_area
    JOIN ref_geo.bib_areas_types AS bat
        ON bat.id_type = la.id_type
WHERE bat.type_code = 'DEP'
GROUP BY la.area_code, la.area_name ;

-- Count observation by departement with optimitzed geometry (tmp_subdivided_area)
-- More accurate !
-- 4mn15
SELECT
    la.area_code,
	la.area_name,
    COUNT(s.id_synthese) AS obs_nbre
FROM gn_synthese.synthese AS s
	JOIN ref_geo.tmp_subdivided_area AS tsa
		ON st_intersects(st_transform(s.the_geom_point, 2154), tsa.geom)
	JOIN ref_geo.l_areas AS la
		ON tsa.id_area = la.id_area
WHERE tsa.id_type = 26
GROUP BY la.area_code, la.area_name ;
