BEGIN;

\echo '-------------------------------------------------------------------------------'
\echo 'Upserts validations in gn_commons.t_validations.'

SET client_encoding = 'UTF8';


\echo '-------------------------------------------------------------------------------'
\echo 'Disable trigger "tri_insert_synthese_update_validation_status"'
ALTER TABLE gn_commons.t_validations DISABLE TRIGGER tri_insert_synthese_update_validation_status ;

\echo '-------------------------------------------------------------------------------'
\echo 'Deleting in "t_validations" observations UUID not found in Synthese'

WITH validations_to_delete AS (
    SELECT DISTINCT v.uuid_attached_row
    FROM gn_commons.t_validations AS v
        LEFT JOIN gn_synthese.synthese AS s
            ON v.uuid_attached_row = s.unique_id_sinp
    WHERE s.id_synthese IS NULL
)
DELETE FROM gn_commons.t_validations AS v
USING validations_to_delete AS vtd
WHERE v.uuid_attached_row = vtd.uuid_attached_row ;


\echo '-------------------------------------------------------------------------------'
\echo 'Batch updating in "t_validations" of the inserted or updated synthese observations'

\echo 'Set config "upsert_validations.last_maintenance_date":'
SELECT set_config('upsert_validations.last_maintenance_date', :'lastMaintenanceDate', false);

DO $$
DECLARE
    step INTEGER ;
    stopAt INTEGER ;
    offsetCnt INTEGER := 0 ;
    lastIdData INT := 0 ;
    affectedRows INTEGER := 1 ;
    insertedRows INTEGER ;
    updatedRows INTEGER ;
    duplicatedRows INTEGER ;
    loopStartTime TIMESTAMP ;
    totalRead INTEGER := 0 ;
    totalInserted INTEGER := 0 ;
    totalUpdated INTEGER := 0 ;
    totalDuplicated INTEGER := 0 ;
    globalStartTime TIMESTAMP := clock_timestamp() ;
    lastMaintenanceDate TIMESTAMP :=
        current_setting('upsert_validations.last_maintenance_date')::TIMESTAMP ;
BEGIN
    -- Set dynamicly stopAt and step
    SELECT COUNT(*) INTO stopAt
    FROM gn_synthese.synthese
    WHERE id_nomenclature_valid_status IS NOT NULL
        AND (
            meta_create_date >= lastMaintenanceDate
            OR meta_update_date >= lastMaintenanceDate
        ) ;
    step := gn_imports.computeImportStep(stopAt) ;

    RAISE NOTICE 'Total found: %, step used: %', stopAt, step ;

    RAISE NOTICE 'Start to loop on observations to upsert data in "t_validations" table' ;
    WHILE affectedRows > 0 LOOP

        RAISE NOTICE '-------------------------------------------------' ;
        RAISE NOTICE 'Try to upsert % validations from %', step, offsetCnt ;

        loopStartTime := clock_timestamp();

        WITH validations_to_upsert AS (
            SELECT
                id_synthese,
                unique_id_sinp::uuid AS uuid_attached_row,
                id_nomenclature_valid_status,
                gn_commons.determine_auto_validation(validator, meta_validation_date, id_nomenclature_valid_status) AS validation_auto,
                utilisateurs.get_one_role_id_from_uuid_in_string(validator) AS id_validator,
                gn_commons.format_validation_comment(validation_comment, validator) AS validation_comment,
                meta_validation_date AS validation_date
            FROM gn_synthese.synthese
            WHERE id_synthese > lastIdData
                AND id_nomenclature_valid_status IS NOT NULL
                AND (
                    meta_create_date >= lastMaintenanceDate
                    OR meta_update_date >= lastMaintenanceDate
                )
            ORDER BY id_synthese ASC
            LIMIT step
        ),
        updated AS (
            UPDATE gn_commons.t_validations AS v SET
                id_nomenclature_valid_status = vtu.id_nomenclature_valid_status,
                validation_auto = vtu.validation_auto,
                id_validator = vtu.id_validator,
                validation_comment = vtu.validation_comment
            FROM validations_to_upsert AS vtu
            WHERE v.uuid_attached_row = vtu.uuid_attached_row
                AND v.validation_date = vtu.validation_date
            RETURNING v.uuid_attached_row, v.validation_date
        ),
        inserted AS (
            INSERT INTO gn_commons.t_validations (
                uuid_attached_row,
                id_nomenclature_valid_status,
                validation_auto,
                id_validator,
                validation_comment,
                validation_date
            )
            SELECT
                vtu.uuid_attached_row,
                vtu.id_nomenclature_valid_status,
                vtu.validation_auto,
                vtu.id_validator,
                vtu.validation_comment,
                vtu.validation_date
            FROM validations_to_upsert AS vtu
                LEFT JOIN updated AS u
                    ON (
                        vtu.uuid_attached_row = u.uuid_attached_row
                        AND vtu.validation_date = u.validation_date
                    )
            WHERE u.uuid_attached_row IS NULL
            RETURNING uuid_attached_row
        )
        SELECT
            COALESCE((SELECT MAX(id_synthese) FROM validations_to_upsert), lastIdData),
            (SELECT count(*) FROM validations_to_upsert) AS validations_to_upsert_count,
            (SELECT count(*) FROM updated) AS updated_count,
            (SELECT count(*) FROM inserted) AS inserted_count
        INTO
            lastIdData,
            affectedRows,
            updatedRows,
            insertedRows ;

        totalRead := totalRead + affectedRows ;
        totalInserted := totalInserted + insertedRows ;
        totalUpdated := totalUpdated + updatedRows ;
        duplicatedRows := affectedRows - (insertedRows + updatedRows) ;
        totalDuplicated := totalDuplicated + duplicatedRows ;

        RAISE NOTICE 'Lot read: % rows (Last id_synthese : %)', affectedRows, lastIdData ;
        RAISE NOTICE 'New inserted rows: % ; Updated : %', insertedRows, updatedRows ;
        RAISE NOTICE 'Duplicates: %', duplicatedRows ;
        RAISE NOTICE 'Loop execution time: %', clock_timestamp() - loopStartTime ;

        offsetCnt := offsetCnt + (step) ;
    END LOOP ;

    RAISE NOTICE '=================================================' ;
    RAISE NOTICE 'IMPORT DONE !' ;
    RAISE NOTICE 'Total number of lines read: %', totalRead ;
    RAISE NOTICE 'Total number of inserted lines: %', totalInserted ;
    RAISE NOTICE 'Total number of updated lines: %', totalUpdated ;
    RAISE NOTICE 'Total time : %', clock_timestamp() - globalStartTime ;
END
$$ ;


\echo '-------------------------------------------------------------------------------'
\echo 'Enable trigger "tri_insert_synthese_update_validation_status"'
ALTER TABLE gn_commons.t_validations ENABLE TRIGGER tri_insert_synthese_update_validation_status ;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
