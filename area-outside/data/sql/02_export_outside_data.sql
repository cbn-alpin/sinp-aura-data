-- Required rights: DB OWNER
-- GeoNature database compatibility : v2.6.0+
-- Export observations in synthese not linked to areas by sources list.
BEGIN;


\echo '-------------------------------------------------------------------------------'
\echo 'Export "tmp_outside_all" data to CSV file'
COPY (
    SELECT
        id_synthese,
        unique_id_sinp,
        entity_source_pk_value,
        cd_nom,
        nom_cite,
        the_geom_local,
        date_min,
        additional_data
    FROM gn_synthese.tmp_outside_all
    WHERE id_source >= :idSourceMin AND id_source <= :idSourceMax
)
TO :'csvFilePath' DELIMITER E'\t' CSV HEADER NULL '\N' ;


\echo '-------------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
