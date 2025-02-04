\echo 'Fix Gn2Pg error log duplicate UUID entries before 2024-11-01.'
\echo 'Rights: db-owner'
-- Usage: psql -h "localhost" -U "<db-owner-name>" -d "<db-name>" -f <path-to-this-sql-file>
-- Ex.: psql -h "localhost" -U "geonatadmin" -d "geonature2db" -f ~/data/lpo/data/sql/fix/004_*

\echo '----------------------------------------------------------------------------'
\echo 'Start deleting transaction '
BEGIN;


\echo '-------------------------------------------------------------------------------'
\echo 'Remove duplicate UUID between LPO and FLAVIA from FLAVIA data_json entries'
WITH flavia_duplicated_uuid AS (
    SELECT
        (item ->> 'id_perm_sinp')::uuid AS id_perm_sinp
    FROM gn2pg_lpo.error_log AS el
    WHERE last_ts > '2024-11-01'
        AND split_part(
            split_part(error::text, ') '::text, 2),
            'DETAIL'::text, 1
        ) ILIKE '%duplicate key value violates unique constraint "unique_id_sinp_unique"%'
    AND EXISTS (
            SELECT 'TRUE'
            FROM gn_synthese.synthese AS s
            WHERE s.unique_id_sinp = (el.item ->> 'id_perm_sinp')::uuid
                AND s.id_source <> gn2pg_lpo.fct_c_get_or_insert_source(el."source")
    )
)
DELETE FROM gn2pg_flavia.data_json
WHERE "uuid" IN (SELECT id_perm_sinp FROM flavia_duplicated_uuid) ;


\echo '-------------------------------------------------------------------------------'
\echo 'Remove data_json entries where UUID is noted as duplicate in error log'
WITH duplicated_uuid AS (
    SELECT (item ->> 'id_perm_sinp')::uuid AS id_perm_sinp
    FROM gn2pg_lpo.error_log
    WHERE split_part(
                split_part(error::text, ') '::text, 2),
                'DETAIL'::text, 1
            ) ILIKE '%duplicate key value violates unique constraint "unique_id_sinp_unique"%'
)
DELETE FROM gn2pg_lpo.data_json
WHERE "uuid" IN (SELECT id_perm_sinp FROM duplicated_uuid) ;


\echo '-------------------------------------------------------------------------------'
\echo 'Reinsert in data_json entries where UUID is noted as duplicate in error log'
INSERT INTO gn2pg_lpo.data_json (
    "source",
    controler,
    "type",
    id_data,
    uuid,
    item
)
WITH last_error_log AS (
	SELECT
	    id_data,
    	MAX(last_ts) AS max_last_ts
	FROM gn2pg_lpo.error_log AS el
	WHERE split_part(
	        split_part(error::text, ') '::text, 2),
	        'DETAIL'::text, 1
	    ) ILIKE '%duplicate key value violates unique constraint "unique_id_sinp_unique"%'
	    AND NOT EXISTS (
	        SELECT 'TRUE'
	        FROM gn_synthese.synthese AS s
	        WHERE s.unique_id_sinp = (el.item ->> 'id_perm_sinp')::uuid
	            AND s.id_source <> gn2pg_lpo.fct_c_get_or_insert_source(el."source")
	   )
	GROUP BY id_data
)
SELECT
    el."source",
    el.controler,
    'synthese_with_metadata',
    el.id_data,
    (el.item ->> 'id_perm_sinp')::uuid AS id_perm_sinp,
    el.item
FROM gn2pg_lpo.error_log AS el
	JOIN last_error_log AS lel
		ON (lel.id_data = el.id_data AND lel.max_last_ts = el.last_ts)
WHERE split_part(
        split_part(el.error::text, ') '::text, 2),
        'DETAIL'::text, 1
    ) ILIKE '%duplicate key value violates unique constraint "unique_id_sinp_unique"%'
   AND NOT EXISTS (
        SELECT 'TRUE'
        FROM gn_synthese.synthese AS s
        WHERE s.unique_id_sinp = (el.item ->> 'id_perm_sinp')::uuid
            AND s.id_source <> gn2pg_lpo.fct_c_get_or_insert_source(el."source")
   ) ;


\echo '-------------------------------------------------------------------------------'
\echo 'Clean error_log from data reinserted into data_json'
DELETE FROM gn2pg_lpo.error_log AS el
USING gn2pg_lpo.data_json AS dj
WHERE el."source" = dj."source"
    AND el.id_data = dj.id_data
    AND el.last_ts < dj.update_ts
    AND split_part(
        split_part(el.error::text, ') '::text, 2),
        'DETAIL'::text, 1
    ) ILIKE '%duplicate key value violates unique constraint "unique_id_sinp_unique"%' ;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is OK:'
COMMIT;
