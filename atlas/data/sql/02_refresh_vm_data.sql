-- Script to refresh MV after use of pg_restore

-- Geo
REFRESH MATERIALIZED VIEW atlas.t_layer_territoire;
REFRESH MATERIALIZED VIEW atlas.t_subdivided_territory;
REFRESH MATERIALIZED VIEW atlas.t_mailles_territoire;
REFRESH MATERIALIZED VIEW atlas.l_communes;
REFRESH MATERIALIZED VIEW atlas.vm_communes;

-- Tax
REFRESH MATERIALIZED VIEW atlas.vm_taxref;

-- Data
REFRESH MATERIALIZED VIEW atlas.vm_observations;
REFRESH MATERIALIZED VIEW atlas.vm_observations_mailles;
REFRESH MATERIALIZED VIEW atlas.vm_mois;

REFRESH MATERIALIZED VIEW atlas.vm_altitudes;

REFRESH MATERIALIZED VIEW atlas.vm_taxons;
REFRESH MATERIALIZED VIEW atlas.vm_cor_taxon_attribut;
REFRESH MATERIALIZED VIEW atlas.vm_search_taxon;
REFRESH MATERIALIZED VIEW atlas.vm_medias;
REFRESH MATERIALIZED VIEW atlas.vm_taxons_plus_observes;
REFRESH MATERIALIZED VIEW atlas.vm_stats;

-- Avoid truncate t_cache for restore
-- TRUNCATE atlas.t_cache ;
