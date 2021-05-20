-- Required rights: DB OWNER
-- GeoNature database compatibility : v2.3.0+
-- Remove useless areas from l_areas
-- TODO: check speed with constraint fk_li_municipalities_id_area and fk_li_grids_id_area enable or not

BEGIN;


\echo '----------------------------------------------------------------------------'
\echo 'Delete areas not intersect with SINP area'
DELETE FROM ref_geo.l_areas AS la
WHERE (
    la.area_code NOT SIMILAR TO :'SinpDepRegexp' AND la.id_type = ref_geo.get_id_area_type_by_code('DEP')
) OR (
    la.area_code NOT SIMILAR TO :'SinpComRegexp' AND la.id_type = ref_geo.get_id_area_type_by_code('COM')
)
;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
