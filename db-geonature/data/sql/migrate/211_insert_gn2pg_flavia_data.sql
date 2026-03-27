-- Script to trigger Gn2PG Flavia data insert to destination DB
\echo '-------------------------------------------------------------------------------'
\echo 'Batch insertion of the Flavia metadata in gn_meta with the Gn2Pg trigger'

DO $$
DECLARE
    step INTEGER := 500 ;
    total INTEGER ;
    startTime TIMESTAMP ;
    i INTEGER := 0;
    id_record RECORD ;
    curs_data CURSOR FOR
        SELECT m.uuid
        FROM gn2pg_flavia.metadata_json  AS m
        WHERE m.source = 'flavia'
        --  AND d.unique_id_sinp NOT IN (
        --    SELECT DISTINCT uuid
        --    FROM gn2pg_flavia.error_log
        --    WHERE source = 'flavia' AND controler = 'metadata'
        --  )
        ORDER BY m.uuid ;
BEGIN
    SELECT COUNT(*) INTO total FROM gn2pg_flavia.metadata_json ;
    RAISE NOTICE 'Total found: %, step used: %', total, step ;

    RAISE NOTICE '-------------------------------------------------' ;
    RAISE NOTICE 'Start to loop on Flavia metadata to trigger insert in "gn_meta" schema' ;
    FOR id_record IN curs_data LOOP
        i := i + 1;

        UPDATE gn2pg_flavia.metadata_json
        SET uuid = uuid
        WHERE source = 'Flavia' AND uuid = id_record.uuid ;

        IF i % step = 0 OR i = 1 THEN
            IF i % step = 0 THEN
                RAISE NOTICE 'Processed record % / %', i, total;
                RAISE NOTICE 'Loop execution time: %', clock_timestamp() - startTime;
            END IF;
            startTime := clock_timestamp();
            RAISE NOTICE '-------------------------------------------------';
            RAISE NOTICE 'Triggering % Flavia metadata from %', step, i ;
        END IF;
    END LOOP;
END
$$ ;


\echo '-------------------------------------------------------------------------------'
\echo 'Disable all triggers on gn_synthese.synthese'
ALTER TABLE gn_synthese.synthese DISABLE TRIGGER ALL;

\echo '-------------------------------------------------------------------------------'
\echo 'Batch insertion of the Flavia data in Synthese with the Gn2Pg trigger'

DO $$
DECLARE
    step INTEGER := 50000 ;
    total INTEGER ;
    startTime TIMESTAMP ;
    i INTEGER := 0;
    id_record RECORD ;
    curs_data CURSOR FOR
        SELECT d.id_data
        FROM gn2pg_flavia.data_json AS d
        WHERE d.source = 'flavia'
        --  AND d.unique_id_sinp NOT IN (
        --    SELECT DISTINCT uuid
        --    FROM gn2pg_flavia.error_log
        --    WHERE source = 'flavia' AND controler = 'data'
        --  )
        ORDER BY d.id_data ;
BEGIN
    SELECT COUNT(*) INTO total FROM gn2pg_flavia.data_json ;
    RAISE NOTICE 'Total found: %, step used: %', total, step ;

    RAISE NOTICE '-------------------------------------------------' ;
    RAISE NOTICE 'Start to loop on Flavia data to trigger insert in "gn_synthese.synthese" table' ;
    FOR id_record IN curs_data LOOP
        i := i + 1;

        UPDATE gn2pg_flavia.data_json
        SET id_data = id_data
        WHERE source = 'flavia' AND id_data = id_record.id_data ;

        IF i % step = 0 OR i = 1 THEN
            IF i % step = 0 THEN
                RAISE NOTICE 'Processed record % / %', i, total;
                RAISE NOTICE 'Loop execution time: %', clock_timestamp() - startTime;
            END IF;
            startTime := clock_timestamp();
            RAISE NOTICE '-------------------------------------------------';
            RAISE NOTICE 'Triggering % Flavia data from %', step, i ;
        END IF;
    END LOOP;
END
$$ ;


\echo '-------------------------------------------------------------------------------'
\echo 'Enable trigger all triggers on gn_synthese.synthese'
ALTER TABLE gn_synthese.synthese ENABLE TRIGGER ALL;
