\echo 'Fix Gn2Pg error log duplicate UUID entries after 2024-11-01.'
\echo 'Rights: db-owner'
-- Usage: psql -h "localhost" -U "<db-owner-name>" -d "<db-name>" -f <path-to-this-sql-file>
-- Ex.: psql -h "localhost" -U "geonatadmin" -d "geonature2db" -f ~/data/lpo/data/sql/fix/003_*

\echo '----------------------------------------------------------------------------'
\echo 'Start deleting transaction'
BEGIN;


\echo '----------------------------------------------------------------------------'
\echo 'Add index only on entity_source_pk_value field to speed up deletion'
CREATE INDEX IF NOT EXISTS i_synthese_entity_source_pk_value ON gn_synthese.synthese
USING btree (entity_source_pk_value) ;


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
SELECT
    "source",
    controler,
    'synthese_with_metadata',
    id_data,
    (item ->> 'id_perm_sinp')::uuid,
    item
FROM gn2pg_lpo.error_log AS el
WHERE last_ts > '2024-11-01'
    AND split_part(
        split_part(error::text, ') '::text, 2),
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


-- Query to see id_data/id_synthese in error_log, data_json and synthese with observation UUID as join
-- WITH error_log_uuid AS (
-- 	SELECT
-- 		el.id_data,
-- 		(el.item ->> 'id_synthese') AS id_synthese,
-- 		(el.item ->> 'id_perm_sinp')::uuid AS "uuid",
-- 		el.last_ts
-- 	FROM gn2pg_lpo.error_log AS el
-- 	WHERE el.error ILIKE '%duplicate key value violates unique constraint "unique_id_sinp_unique"%'
-- 		AND el.last_ts > '2024-11-04 00:00'
-- )
-- SELECT
-- 	elu."uuid",
-- 	elu.id_data::varchar AS error_log_id_data,
-- 	elu.id_synthese::varchar AS error_log_item_id_synthese,
-- 	--elu."uuid" AS error_log_uuid,
-- 	dj.id_data::varchar AS data_json_id_data,
-- 	--dj."uuid" AS data_json_uuid,
-- 	s.entity_source_pk_value::varchar AS gn_synthese_entity_source_pk_value
-- 	--s.unique_id_sinp AS gn_synthese_uuid
-- FROM error_log_uuid AS elu
-- 	LEFT JOIN gn2pg_lpo.data_json AS dj
-- 		ON elu."uuid" = dj."uuid"
-- 	LEFT JOIN gn_synthese.synthese AS s
-- 		ON elu."uuid" = s.unique_id_sinp
-- WHERE dj."uuid" IS NOT NULL
-- ORDER BY elu.last_ts ;


-- Query to find existing UUID in other source :
-- SELECT
--     "source",
--     id_data,
--     (item ->> 'id_perm_sinp')::uuid,
--     item
-- FROM gn2pg_lpo.error_log AS el
-- WHERE last_ts > '2024-11-01'
--     AND split_part(
--         split_part(error::text, ') '::text, 2),
--         'DETAIL'::text, 1
--     ) ILIKE '%duplicate key value violates unique constraint "unique_id_sinp_unique"%'
--    AND EXISTS (
--         SELECT 'TRUE'
--         FROM gn_synthese.synthese AS s
--         WHERE s.unique_id_sinp = (el.item ->> 'id_perm_sinp')::uuid
--             AND s.id_source <> gn2pg_lpo.fct_c_get_or_insert_source(el."source")
--    ) ;
