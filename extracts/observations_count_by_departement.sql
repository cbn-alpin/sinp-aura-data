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
