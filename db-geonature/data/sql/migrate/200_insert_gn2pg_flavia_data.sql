-- Script to trigger Gn2PG Flavia data insert to destination DB

\echo '-------------------------------------------------------------------------------'
\echo 'Disable triggers on Synthese'

\echo 'Disable trigger "tri_insert_calculate_sensitivity"'
ALTER TABLE gn_synthese.synthese DISABLE TRIGGER tri_insert_calculate_sensitivity ;

\echo 'Disable trigger "tri_update_calculate_sensitivity"'
ALTER TABLE gn_synthese.synthese DISABLE TRIGGER tri_update_calculate_sensitivity ;


\echo 'Disable trigger "tri_insert_cor_area_synthese"'
ALTER TABLE gn_synthese.synthese DISABLE TRIGGER tri_insert_cor_area_synthese ;

\echo 'Disable trigger "tri_update_cor_area_synthese"'
ALTER TABLE gn_synthese.synthese DISABLE TRIGGER tri_update_cor_area_synthese ;


\echo '-------------------------------------------------------------------------------'
\echo 'Batch insertion of the Flavia data in Synthese with the Gn2Pg trigger'

DO $$
DECLARE
    step INTEGER := 50000 ;
    stopAt INTEGER ;
    offsetCnt INTEGER := 0 ;
    affectedRows INTEGER ;
    startTime TIMESTAMP ;
BEGIN
    -- Set dynamicly stopAt
    SELECT COUNT(*) INTO stopAt FROM gn2pg_flavia.data_json ;
    RAISE NOTICE 'Total found: %, step used: %', stopAt, step ;

    RAISE NOTICE 'Start to loop on Flavia data to trigger insert in "gn_synthese.synthese" table' ;
    WHILE offsetCnt < stopAt LOOP

        RAISE NOTICE '-------------------------------------------------' ;
        RAISE NOTICE 'Try to insert % Flavia data from %', step, offsetCnt ;

        startTime := clock_timestamp();

        WITH ordered_data AS (
            SELECT id_data
            FROM gn2pg_flavia.data_json
            ORDER BY id_data ASC
            OFFSET offsetCnt
            LIMIT step
        )
        UPDATE gn2pg_flavia.data_json AS d
        SET id_data = d.id_data
        FROM ordered_data AS od
        WHERE d.id_data = od.id_data ;

        GET DIAGNOSTICS affectedRows = ROW_COUNT;
        RAISE NOTICE 'Insert affected rows: %', affectedRows ;
        RAISE NOTICE 'Loop execution time: %', clock_timestamp() - startTime;

        offsetCnt := offsetCnt + (step) ;
    END LOOP ;
END
$$ ;


\echo '-------------------------------------------------------------------------------'
\echo 'Enable triggers on Synthese'

\echo 'Enable trigger "tri_insert_calculate_sensitivity"'
ALTER TABLE gn_synthese.synthese ENABLE TRIGGER tri_insert_calculate_sensitivity ;

\echo 'Enable trigger "tri_update_calculate_sensitivity"'
ALTER TABLE gn_synthese.synthese ENABLE TRIGGER tri_update_calculate_sensitivity ;


\echo 'Enable trigger "tri_insert_cor_area_synthese"'
ALTER TABLE gn_synthese.synthese ENABLE TRIGGER tri_insert_cor_area_synthese ;

\echo 'Enable trigger "tri_update_cor_area_synthese"'
ALTER TABLE gn_synthese.synthese ENABLE TRIGGER tri_update_cor_area_synthese ;
