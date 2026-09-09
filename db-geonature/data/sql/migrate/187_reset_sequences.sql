-- Migrate to GeoNature v2.17
-- Reset all sequences.
-- It's necessary after TRUNCATE and COPY executed in destination database.


BEGIN;

\echo '----------------------------------------------------------------------------'
\echo 'Reset all sequences of database'

SELECT
    substring(column_default, '''(.*)''') AS sequence_name,
    reset_sequence(table_schema, table_name, column_name)
FROM information_schema.columns
WHERE column_default LIKE 'nextval%' ;

DO $$
DECLARE
    rec RECORD;
BEGIN
    FOR rec IN
        SELECT
            n.nspname AS schema_name,
            c.relname AS table_name,
            a.attname AS column_name
        FROM pg_class AS c
            JOIN pg_namespace AS n
                ON n.oid = c.relnamespace
            JOIN pg_attribute AS a
                ON a.attrelid = c.oid
        WHERE c.relkind = 'r' -- Only the tables
          AND a.attnum > 0 -- Only the real column
          AND NOT a.attisdropped
          -- Check if the column has an associated column
          AND pg_get_serial_sequence(n.nspname || '.' || c.relname, a.attname) IS NOT NULL
          -- Exclude system schemas
          AND n.nspname NOT IN ('pg_catalog', 'information_schema')
    LOOP
        -- Perform the function for each found sequences
        PERFORM public.reset_sequence(rec.schema_name, rec.table_name, rec.column_name);
    END LOOP;
END;
$$;

\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is OK:'
COMMIT ;
