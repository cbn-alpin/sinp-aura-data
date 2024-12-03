\echo 'Fix Gn2Pg error log duplicate UUID entries.'
\echo 'Rights: db-owner'
-- Usage: psql -h "localhost" -U "<db-owner-name>" -d "<db-name>" -f <path-to-this-sql-file>
-- Ex.: psql -h "localhost" -U "geonatadmin" -d "geonature2db" -f ~/data/lpo/data/sql/fix/003_*

BEGIN;

\echo '-------------------------------------------------------------------------------'
\echo 'Remove data_json entries where UUID is noted as duplicate in error log'
WITH duplicated_uuid AS (
    SELECT (item ->> 'id_perm_sinp')::uuid AS id_perm_sinp
    FROM gn2pg_lpo.error_log
    WHERE last_ts > '2024-11-01'
        AND split_part(
                split_part(error::text, ') '::text, 2),
                'DETAIL'::text, 1
            ) ILIKE '%duplicate key value violates unique constraint "unique_id_sinp_unique"%'
)
DELETE FROM gn2pg_lpo.data_json
WHERE uuid IN (SELECT id_perm_sinp FROM duplicated_uuid) ;


\echo '-------------------------------------------------------------------------------'
\echo 'Reinsert in data_json entries where UUID is noted as duplicate in error log'
INSERT INT gn2pg_lpo.data_json (
    source,
    controler,
    "type",
    id_data,
    uuid,
    item
)
SELECT
    source,
    controler,
    'synthese_with_metadata',
    id_data,
    (item ->> 'id_perm_sinp')::uuid,
    item
FROM gn2pg_lpo.error_log
WHERE last_ts > '2024-11-01'
    AND split_part(
        split_part(error::text, ') '::text, 2),
        'DETAIL'::text, 1
    ) ILIKE '%duplicate key value violates unique constraint "unique_id_sinp_unique"%' ;


\echo '-------------------------------------------------------------------------------'
\echo 'Clean error_log from data reinserted into data_json'
DELETE FROM gn2pg_lpo.error_log AS el
USING gn2pg_lpo.data_json AS dj
WHERE dj.source = el.source
    AND dj.id_data = el.id_data
    AND el.last_ts < dj.update_ts
    AND split_part(
        split_part(el.error::text, ') '::text, 2),
        'DETAIL'::text, 1
    ) ILIKE '%duplicate key value violates unique constraint "unique_id_sinp_unique"%' ;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is OK:'
COMMIT;
