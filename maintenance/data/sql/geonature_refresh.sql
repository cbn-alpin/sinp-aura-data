-- Refresh all GeoNature SINP AURA specific materialized views

-- Enable timing
\timing

BEGIN ;

\echo '----------------------------------------------------------------'
\echo 'Refreshing gn_exports.catalog_taxa_region:'
REFRESH MATERIALIZED VIEW CONCURRENTLY gn_exports.catalog_taxa_region ;

\echo '----------------------------------------------------------------'
\echo 'Refreshing gn_exports.synthese:'
REFRESH MATERIALIZED VIEW CONCURRENTLY gn_exports.synthese ;

\echo '----------------------------------------------------------------'
\echo 'Refreshing gn_exports.pnr_haut_jura:'
REFRESH MATERIALIZED VIEW CONCURRENTLY gn_exports.pnr_haut_jura ;

\echo '----------------------------------------------------------------'
\echo 'Refreshing gn_exports.pnr_livradois_forez_1:'
REFRESH MATERIALIZED VIEW CONCURRENTLY gn_exports.pnr_livradois_forez_1 ;

\echo '----------------------------------------------------------------'
\echo 'Refreshing gn_exports.pnr_livradois_forez_2:'
REFRESH MATERIALIZED VIEW CONCURRENTLY gn_exports.pnr_livradois_forez_2 ;

\echo '----------------------------------------------------------------'
\echo 'Refreshing gn_exports.pnr_massif_bauges:'
REFRESH MATERIALIZED VIEW CONCURRENTLY gn_exports.pnr_massif_bauges ;

\echo '----------------------------------------------------------------'
\echo 'Refreshing gn_exports.pnr_pilat:'
REFRESH MATERIALIZED VIEW CONCURRENTLY gn_exports.pnr_pilat ;

\echo '----------------------------------------------------------------'
\echo 'Refreshing gn_exports.pnr_vercors_1:'
REFRESH MATERIALIZED VIEW CONCURRENTLY gn_exports.pnr_vercors_1 ;

\echo '----------------------------------------------------------------'
\echo 'Refreshing gn_exports.pnr_vercors_2:'
REFRESH MATERIALIZED VIEW CONCURRENTLY gn_exports.pnr_vercors_2 ;

\echo '----------------------------------------------------------------'
\echo 'Refreshing gn_exports.pnr_volcans_auvergne_1:'
REFRESH MATERIALIZED VIEW CONCURRENTLY gn_exports.pnr_volcans_auvergne_1 ;

\echo '----------------------------------------------------------------'
\echo 'Refreshing gn_exports.pnr_volcans_auvergne_2:'
REFRESH MATERIALIZED VIEW CONCURRENTLY gn_exports.pnr_volcans_auvergne_2 ;

\echo '----------------------------------------------------------------'
\echo 'Refreshing gn_exports.pnr_volcans_auvergne_3:'
REFRESH MATERVIEW CONCIALIZED URRENTLY gn_exports.pnr_volcans_auvergne_3 ;

\echo '----------------------------------------------------------------'
\echo 'Refreshing gn_exports.pnr_volcans_auvergne_4:'
REFRESH MATERVIEW CONCIALIZED URRENTLY gn_exports.pnr_volcans_auvergne_4 ;

\echo '----------------------------------------------------------------'
\echo 'Refreshing gn_exports.lo_parvi_1:'
REFRESH MATERIALIZED VIEW CONCURRENTLY gn_exports.lo_parvi_1 ;

\echo '----------------------------------------------------------------'
\echo 'Refreshing gn_exports.lo_parvi_2:'
REFRESH MATERIALIZED VIEW CONCURRENTLY gn_exports.lo_parvi_2 ;

\echo '----------------------------------------------------------------'
\echo 'Refreshing gn_exports.pnr_chartreuse:'
REFRESH MATERIALIZED VIEW CONCURRENTLY gn_exports.pnr_chartreuse ;

\echo '----------------------------------------------------------------'
\echo 'Refreshing gn_exports.onf:'
REFRESH MATERIALIZED VIEW CONCURRENTLY gn_exports.onf ;

\echo '----------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
