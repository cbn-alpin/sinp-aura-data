-- Migrate to GeoNature v2.16/2.17
-- Clean ref_geo data after migrations

BEGIN;

\echo '----------------------------------------------------------------------------'
\echo 'Insert data in li_grids'

INSERT INTO ref_geo.li_grids(id_grid, id_area, cxmin, cxmax, cymin, cymax)
    SELECT
        a.area_code,
        a.id_area,
        ST_XMin(a.geom),
        ST_XMax(a.geom),
        ST_YMin(a.geom),
        ST_YMax(a.geom)
    FROM ref_geo.l_areas AS a
        JOIN ref_geo.bib_areas_types AS t
            ON a.id_type = t.id_type
    WHERE t.type_code IN ('M1', 'M2', 'M5', 'M10', 'M20', 'M50')
ON CONFLICT DO NOTHING ;

\echo '----------------------------------------------------------------------------'
\echo 'Reindex li_grids:'

REINDEX INDEX ref_geo.index_li_grids_id_area ;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is OK:'
COMMIT ;
