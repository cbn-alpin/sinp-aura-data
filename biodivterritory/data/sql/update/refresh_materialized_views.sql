-- Script to refresh Materialized Views of Biodiv'territory.

-- Enable timing
\timing

BEGIN ;

\echo '----------------------------------------------------------------'
\echo 'Refreshing gn_biodivterritory.mv_l_areas_autocomplete:'
REFRESH MATERIALIZED VIEW CONCURRENTLY gn_biodivterritory.mv_l_areas_autocomplete;

\echo '----------------------------------------------------------------'
\echo 'Refreshing gn_biodivterritory.mv_territory_general_stats:'
REFRESH MATERIALIZED VIEW CONCURRENTLY gn_biodivterritory.mv_territory_general_stats;

\echo '----------------------------------------------------------------'
\echo 'Refreshing gn_biodivterritory.mv_area_ntile_limit:'
REFRESH MATERIALIZED VIEW CONCURRENTLY gn_biodivterritory.mv_area_ntile_limit;

\echo '----------------------------------------------------------------'
\echo 'Refreshing gn_biodivterritory.mv_general_stats:'
REFRESH MATERIALIZED VIEW CONCURRENTLY gn_biodivterritory.mv_general_stats;

\echo '----------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
