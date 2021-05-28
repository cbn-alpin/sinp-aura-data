-- Droits d'éxecution nécessaire : DB OWNER
-- Script to refresh NOT concurently all Materialized views after use of pg_restore
-- Use: psql -h localhost -U geonatadmin -d gnatlas -f ./db-atlas/data/sql/02_refresh_vm_all.sql
-- For content of this script see functions atlas.refresh_materialized_view_data() and
-- atlas.refresh_materialized_view_reg_geo().
BEGIN ;

\echo '----------------------------------------------------------------------------'
\echo 'Refreshing GEO VM...'

\echo 'Refresh t_layer_territoire'
REFRESH MATERIALIZED VIEW atlas.t_layer_territoire;

\echo 'Refresh t_subdivided_territory'
REFRESH MATERIALIZED VIEW atlas.t_subdivided_territory;

\echo 'Refresh t_mailles_territoire'
REFRESH MATERIALIZED VIEW atlas.t_mailles_territoire;

\echo 'Refresh l_communes'
REFRESH MATERIALIZED VIEW atlas.l_communes;

\echo 'Refresh vm_communes'
REFRESH MATERIALIZED VIEW atlas.vm_communes;

\echo '----------------------------------------------------------------------------'
\echo 'Refreshing TAXO VM...'

\echo 'Refresh vm_taxref'
REFRESH MATERIALIZED VIEW atlas.vm_taxref;

\echo '----------------------------------------------------------------------------'
\echo 'Refreshing DATA VM...'

\echo 'Refresh vm_observations'
REFRESH MATERIALIZED VIEW atlas.vm_observations;

\echo 'Refresh vm_observations_mailles'
REFRESH MATERIALIZED VIEW atlas.vm_observations_mailles;

\echo 'Refresh vm_mois'
REFRESH MATERIALIZED VIEW atlas.vm_mois;

\echo 'Refresh vm_altitudes'
REFRESH MATERIALIZED VIEW atlas.vm_altitudes;

\echo 'Refresh vm_taxons'
REFRESH MATERIALIZED VIEW atlas.vm_taxons;

\echo 'Refresh vm_cor_taxon_attribut'
REFRESH MATERIALIZED VIEW atlas.vm_cor_taxon_attribut;

\echo 'Refresh vm_search_taxon'
REFRESH MATERIALIZED VIEW atlas.vm_search_taxon;

\echo 'Refresh vm_medias'
REFRESH MATERIALIZED VIEW atlas.vm_medias;

\echo 'Refresh vm_taxons_plus_observes'
REFRESH MATERIALIZED VIEW atlas.vm_taxons_plus_observes;

\echo 'Refresh vm_stats'
REFRESH MATERIALIZED VIEW atlas.vm_stats;

-- Avoid truncate t_cache for restore
-- TRUNCATE atlas.t_cache ;

\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is OK:'
COMMIT;
