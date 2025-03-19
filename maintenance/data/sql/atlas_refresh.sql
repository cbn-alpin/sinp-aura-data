-- Refresh all Atlas Materialized views

-- Enable timing
\timing

BEGIN ;

-- TAXO

\echo '----------------------------------------------------------------'
\echo 'Refreshing atlas.vm_taxref:'
REFRESH MATERIALIZED VIEW CONCURRENTLY atlas.vm_taxref;

-- GEO

\echo '----------------------------------------------------------------'
\echo 'Refreshing atlas.t_layer_territoire:'
REFRESH MATERIALIZED VIEW CONCURRENTLY atlas.t_layer_territoire;

\echo '----------------------------------------------------------------'
\echo 'Refreshing atlas.vm_subdivided_area:'
REFRESH MATERIALIZED VIEW CONCURRENTLY atlas.vm_subdivided_area;

\echo '----------------------------------------------------------------'
\echo 'Refreshing atlas.l_communes:'
REFRESH MATERIALIZED VIEW CONCURRENTLY atlas.l_communes;

\echo '----------------------------------------------------------------'
\echo 'Refreshing atlas.vm_communes:'
REFRESH MATERIALIZED VIEW CONCURRENTLY atlas.vm_communes;

-- DATA

\echo '----------------------------------------------------------------'
\echo 'Refreshing atlas.municipality_subdivided:'
REFRESH MATERIALIZED VIEW CONCURRENTLY atlas.municipality_subdivided;

\echo '----------------------------------------------------------------'
\echo 'Refreshing atlas.observations_blurred:'
REFRESH MATERIALIZED VIEW CONCURRENTLY atlas.observations_blurred;

\echo '----------------------------------------------------------------'
\echo 'Refreshing atlas.observations_blurred_geometry:'
REFRESH MATERIALIZED VIEW CONCURRENTLY atlas.observations_blurred_geometry;

\echo '----------------------------------------------------------------'
\echo 'Refreshing atlas.observations_blurred_centroid:'
REFRESH MATERIALIZED VIEW CONCURRENTLY atlas.observations_blurred_centroid;

\echo '----------------------------------------------------------------'
\echo 'Refreshing atlas.observations_blurred_centroid:'
REFRESH MATERIALIZED VIEW CONCURRENTLY atlas.observations_blurred_insee;

\echo '----------------------------------------------------------------'
\echo 'Refreshing atlas.vm_observations:'
REFRESH MATERIALIZED VIEW CONCURRENTLY atlas.vm_observations;

\echo '----------------------------------------------------------------'
\echo 'Refreshing atlas.vm_observations_mailles:'
REFRESH MATERIALIZED VIEW CONCURRENTLY atlas.vm_observations_mailles;

\echo '----------------------------------------------------------------'
\echo 'Refreshing atlas.vm_cor_taxon_organism:'
REFRESH MATERIALIZED VIEW CONCURRENTLY atlas.vm_cor_taxon_organism;

\echo '----------------------------------------------------------------'
\echo 'Refreshing atlas.vm_mois:'
REFRESH MATERIALIZED VIEW CONCURRENTLY atlas.vm_mois;

\echo '----------------------------------------------------------------'
\echo 'Refreshing atlas.vm_altitudes:'
REFRESH MATERIALIZED VIEW CONCURRENTLY atlas.vm_altitudes;

\echo '----------------------------------------------------------------'
\echo 'Refreshing atlas.vm_taxons:'
REFRESH MATERIALIZED VIEW CONCURRENTLY atlas.vm_taxons;

\echo '----------------------------------------------------------------'
\echo 'Refreshing atlas.vm_taxon_attribute:'
REFRESH MATERIALIZED VIEW CONCURRENTLY atlas.vm_taxon_attribute;

\echo '----------------------------------------------------------------'
\echo 'Refreshing atlas.vm_search_taxon:'
REFRESH MATERIALIZED VIEW CONCURRENTLY atlas.vm_search_taxon;

\echo '----------------------------------------------------------------'
\echo 'Refreshing atlas.vm_medias:'
REFRESH MATERIALIZED VIEW CONCURRENTLY atlas.vm_medias;

\echo '----------------------------------------------------------------'
\echo 'Refreshing atlas.vm_taxons_plus_observes:'
REFRESH MATERIALIZED VIEW CONCURRENTLY atlas.vm_taxons_plus_observes;

\echo '----------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
