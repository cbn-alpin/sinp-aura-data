-- Droits d'éxecution nécessaire : DB OWNER
-- Refresh data for Materialized views of gnatlas database.
-- Use: psql -h localhost -U geonatadmin -d gnatlas -f ./db-atlas/data/sql/05_refresh_vm_data.sql
-- For content of this script see function atlas.refresh_materialized_view_data()
BEGIN ;

\echo '----------------------------------------------------------------------------'
\echo 'Refresh vm_observations'
REFRESH MATERIALIZED VIEW CONCURRENTLY atlas.vm_observations;

\echo '----------------------------------------------------------------------------'
\echo 'Refresh vm_observations_mailles'
REFRESH MATERIALIZED VIEW CONCURRENTLY atlas.vm_observations_mailles;

\echo '----------------------------------------------------------------------------'
\echo 'Refresh vm_mois'
REFRESH MATERIALIZED VIEW CONCURRENTLY atlas.vm_mois;

\echo '----------------------------------------------------------------------------'
\echo 'Refresh vm_altitudes'
REFRESH MATERIALIZED VIEW CONCURRENTLY atlas.vm_altitudes;

\echo '----------------------------------------------------------------------------'
\echo 'Refresh vm_taxons'
REFRESH MATERIALIZED VIEW CONCURRENTLY atlas.vm_taxons;

\echo '----------------------------------------------------------------------------'
\echo 'Refresh vm_cor_taxon_attribut'
REFRESH MATERIALIZED VIEW CONCURRENTLY atlas.vm_cor_taxon_attribut;

\echo '----------------------------------------------------------------------------'
\echo 'Refresh vm_search_taxon'
REFRESH MATERIALIZED VIEW CONCURRENTLY atlas.vm_search_taxon;

\echo '----------------------------------------------------------------------------'
\echo 'Refresh vm_medias'
REFRESH MATERIALIZED VIEW CONCURRENTLY atlas.vm_medias;

\echo '----------------------------------------------------------------------------'
\echo 'Refresh vm_taxons_plus_observes'
REFRESH MATERIALIZED VIEW CONCURRENTLY atlas.vm_taxons_plus_observes;

\echo '----------------------------------------------------------------------------'
\echo 'Refresh vm_stats'
REFRESH MATERIALIZED VIEW CONCURRENTLY atlas.vm_stats;

\echo '----------------------------------------------------------------------------'
\echo 'Truncate t_cache'
TRUNCATE atlas.t_cache ;

\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is OK:'
COMMIT;
