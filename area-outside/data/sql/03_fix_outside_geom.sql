-- Required rights: DB OWNER
-- GeoNature database compatibility : v2.6.0+
-- Remove geom for outside observations.
BEGIN;


\echo '-------------------------------------------------------------------------------'
\echo 'Remove geom for outside observations'
UPDATE gn_synthese.synthese
SET the_geom_local = NULL,
    the_geom_4326 = NULL,
    the_geom_point = NULL
WHERE id_synthese IN (
    SELECT id_synthese
    FROM gn_synthese.tmp_outside_all
    WHERE the_geom_local IS NOT NULL
) ;


\echo '-------------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
