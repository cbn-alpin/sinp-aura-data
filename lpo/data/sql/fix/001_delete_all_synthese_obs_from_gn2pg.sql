-- Delete all observation in gn_synthese.synthese from GN2PG source.
-- Required rights: DB OWNER
-- GeoNature database compatibility : v2.6.0+

BEGIN;

\echo '-------------------------------------------------------------------------------'
\echo 'Delete all synthese observations from GN2PG source'

DELETE FROM gn_synthese.synthese WHERE id_source = gn_synthese.get_id_source_by_name('lpo') ;

\echo '-------------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
