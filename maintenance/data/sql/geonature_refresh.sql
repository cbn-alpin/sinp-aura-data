-- Refresh all SINP AURA specific materialized views

-- Enable timing
\timing

BEGIN ;

-- TAXO

\echo '----------------------------------------------------------------'
\echo 'Refreshing gn_exports.vm_catalog_taxa_region:'
REFRESH MATERIALIZED VIEW CONCURRENTLY gn_exports.vm_catalog_taxa_region ;

\echo '----------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
