-- Script to export validations from Synthese by source
-- Usage (from local computer): cat ./synthese_validation_by_source.sql | sed 's/${source}/<my-source>/g'| ssh geonat@db-aura-sinp 'export PGPASSWORD="<db-user-pwd>" ; psql -q -h localhost -p 5432 -U gnreader -d geonature2db' > ./$(date +'%F')_validations.csv
-- - <my-source> : replace with the desired source name (see `gn_synthese.t_sources.name_source`)
-- - <db-user-pwd> : replace with the database user password.
\timing off
COPY (
    SELECT
        s.unique_id_sinp,
        ref_nomenclatures.get_cd_nomenclature(s.id_nomenclature_valid_status) AS code_nomenclature_valid_status,
        s."validator",
        s.validation_comment AS comment,
        gn_commons.determine_auto_validation(
            s."validator", s.meta_validation_date, s.id_nomenclature_valid_status
        ) AS "automatic",
        date_trunc('second', s.meta_validation_date)::text AS creation_date,
        NULL AS additional_data,
        date_trunc('second', s.meta_create_date)::text AS meta_create_date,
        date_trunc('second', s.meta_update_date)::text AS meta_update_date,
        'I' AS meta_last_action
    FROM gn_synthese.synthese AS s
    WHERE s.id_nomenclature_valid_status IS NOT NULL
        AND s.id_nomenclature_valid_status != ref_nomenclatures.get_id_nomenclature('STATUT_VALID', '0')
        AND s.id_source = gn_synthese.get_id_source_by_name('${source}')
) TO stdout
WITH (format csv, header, delimiter E'\t') ;
