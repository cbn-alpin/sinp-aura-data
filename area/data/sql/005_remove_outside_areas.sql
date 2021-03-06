-- Required rights: DB OWNER
-- GeoNature database compatibility : v2.3.0+
-- Remove useless areas from l_areas
-- TODO: check speed with constraint fk_li_municipalities_id_area and fk_li_grids_id_area enable or not

BEGIN;


\echo '----------------------------------------------------------------------------'
\echo 'Delete areas not intersect with SINP area'
DELETE FROM ref_geo.l_areas AS a
WHERE NOT EXISTS (
   SELECT 'X' FROM :areaSubdividedTableName AS c
   WHERE public.st_intersects(c.geom, a.geom)
) ;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
