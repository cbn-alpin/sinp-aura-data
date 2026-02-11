-- Migrate to GeoNature v2.16/2.17
-- Clean all necessary tables before migration

BEGIN;

\echo '----------------------------------------------------------------------------'
\echo 'Truncate ref_geo tables'
TRUNCATE
    ref_geo.bib_areas_types,
    ref_geo.l_areas,
    ref_geo.li_grids,
    ref_geo.li_municipalities
CASCADE;

\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is OK:'
COMMIT ;