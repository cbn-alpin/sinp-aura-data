\echo 'Maintenance on l_areas tables after massive deleting'
\echo 'Required rights: superuser'
\echo 'GeoNature database compatibility : v2.3.0+'


\echo '-------------------------------------------------------------------------------'
\echo 'Maintenance on "l_areas"'
VACUUM FULL VERBOSE ref_geo.l_areas ;
ANALYSE VERBOSE ref_geo.l_areas ;
