-- Refresh all GeoNature SINP AURA specific materialized views

-- Enable timing
\timing

BEGIN ;

\echo '----------------------------------------------------------------'
\echo 'Refreshing gn_exports.catalog_taxa_region:'
REFRESH MATERIALIZED VIEW CONCURRENTLY gn_exports.catalog_taxa_region ;

\echo '----------------------------------------------------------------'
\echo 'Refreshing gn_exports.synthese_blurred:'
REFRESH MATERIALIZED VIEW CONCURRENTLY gn_exports.synthese_blurred ;

\echo '----------------------------------------------------------------'
\echo 'Refreshing gn_exports.pnr_haut_jura_blurred:'
REFRESH MATERIALIZED VIEW CONCURRENTLY gn_exports.pnr_haut_jura_blurred ;

\echo '----------------------------------------------------------------'
\echo 'Refreshing gn_exports.pnr_livradois_forez_blurred:'
REFRESH MATERIALIZED VIEW CONCURRENTLY gn_exports.pnr_livradois_forez_blurred ;

\echo '----------------------------------------------------------------'
\echo 'Refreshing gn_exports.pnr_massif_bauges_blurred:'
REFRESH MATERIALIZED VIEW CONCURRENTLY gn_exports.pnr_massif_bauges_blurred ;

\echo '----------------------------------------------------------------'
\echo 'Refreshing gn_exports.pnr_pilat_blurred:'
REFRESH MATERIALIZED VIEW CONCURRENTLY gn_exports.pnr_pilat_blurred ;

\echo '----------------------------------------------------------------'
\echo 'Refreshing gn_exports.pnr_vercors_blurred_1:'
REFRESH MATERIALIZED VIEW CONCURRENTLY gn_exports.pnr_vercors_blurred_1 ;

\echo '----------------------------------------------------------------'
\echo 'Refreshing gn_exports.pnr_vercors_blurred_2:'
REFRESH MATERIALIZED VIEW CONCURRENTLY gn_exports.pnr_vercors_blurred_2 ;

\echo '----------------------------------------------------------------'
\echo 'Refreshing gn_exports.pnr_volcans_auvergne_blurred_1:'
REFRESH MATERIALIZED VIEW CONCURRENTLY gn_exports.pnr_volcans_auvergne_blurred_1 ;

\echo '----------------------------------------------------------------'
\echo 'Refreshing gn_exports.pnr_volcans_auvergne_blurred_2:'
REFRESH MATERIALIZED VIEW CONCURRENTLY gn_exports.pnr_volcans_auvergne_blurred_2 ;

\echo '----------------------------------------------------------------'
\echo 'Refreshing gn_exports.pnr_volcans_auvergne_blurred_3:'
REFRESH MATERIALIZED VIEW CONCURRENTLY gn_exports.pnr_volcans_auvergne_blurred_3 ;

\echo '----------------------------------------------------------------'
\echo 'Refreshing gn_exports.lo_parvi_1:'
REFRESH MATERIALIZED VIEW CONCURRENTLY gn_exports.lo_parvi_1 ;

\echo '----------------------------------------------------------------'
\echo 'Refreshing gn_exports.lo_parvi_2:'
REFRESH MATERIALIZED VIEW CONCURRENTLY gn_exports.lo_parvi_2 ;


\echo '----------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
