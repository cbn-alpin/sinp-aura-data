-- Script to migrate the module Exports configuration data


BEGIN;


\echo '----------------------------------------------------------------------------'
\echo 'Migrate Exports Module configuration data'

WITH export_relations AS (
    SELECT DISTINCT
        te.schema_name,
        te.view_name,
        c.oid AS relid,
        c.relkind
    FROM gn_exports.tmp_exports AS te
        JOIN pg_namespace AS n
            ON n.nspname = te.schema_name
        JOIN pg_class AS c
            ON c.relnamespace = n.oid AND c.relname = te.view_name
),
primary_key_candidates AS (
    SELECT
        c.conrelid AS relid,
        c.conname AS candidate_name,
        0 AS candidate_priority,
        array_agg(a.attname::text ORDER BY k.ordinality) AS key_columns
    FROM pg_constraint AS c
        JOIN export_relations AS er
            ON er.relid = c.conrelid
        CROSS JOIN LATERAL unnest(c.conkey) WITH ORDINALITY AS k(attnum, ordinality)
        JOIN pg_attribute AS a
            ON a.attrelid = c.conrelid AND a.attnum = k.attnum
    WHERE c.contype = 'p'
    GROUP BY c.conrelid, c.conname
),
materialized_view_unique_keys AS (
    SELECT
        i.indrelid AS relid,
        idx.relname AS candidate_name,
        1 AS candidate_priority,
        array_agg(a.attname::text ORDER BY k.ordinality) AS key_columns
    FROM pg_index AS i
        JOIN export_relations AS er
            ON er.relid = i.indrelid AND er.relkind = 'm'
        JOIN pg_class AS idx
            ON idx.oid = i.indexrelid
        CROSS JOIN LATERAL unnest(i.indkey) WITH ORDINALITY AS k(attnum, ordinality)
        JOIN pg_attribute AS a
            ON a.attrelid = i.indrelid AND a.attnum = k.attnum AND a.attnum > 0
    WHERE i.indisunique
        AND i.indisvalid
        AND i.indisready
        AND i.indpred IS NULL
        AND i.indexprs IS NULL
        AND k.ordinality <= i.indnkeyatts
    GROUP BY i.indrelid, idx.relname
),
key_candidates AS (
    SELECT * FROM primary_key_candidates
    UNION ALL
    SELECT * FROM materialized_view_unique_keys
),
selected_keys AS (
    SELECT DISTINCT ON (relid)
        relid,
        key_columns
    FROM key_candidates
    ORDER BY
        relid,
        candidate_priority,
        cardinality(key_columns),
        candidate_name
),
first_view_columns AS (
    SELECT DISTINCT ON (er.relid)
        er.relid,
        a.attname::text AS first_column
    FROM export_relations AS er
        JOIN pg_attribute AS a
            ON a.attrelid = er.relid
    WHERE er.relkind IN ('v', 'm')
        AND a.attnum > 0
        AND NOT a.attisdropped
    ORDER BY er.relid, a.attnum
),
view_pk_columns AS (
    SELECT
        er.schema_name,
        er.view_name,
        COALESCE(
            array_to_string(sk.key_columns, ', '),
            fv.first_column,
            ''
        ) AS view_pk_column
    FROM export_relations AS er
        LEFT JOIN selected_keys AS sk
            ON sk.relid = er.relid
        LEFT JOIN first_view_columns AS fv
            ON fv.relid = er.relid
),
new_exports AS (
    INSERT INTO gn_exports.t_exports (
        label,
        schema_name,
        view_name,
        "desc",
        geometry_field,
        geometry_srid,
        public,
        id_licence,
        view_pk_column
    )
    SELECT
        te.label,
        te.schema_name,
        te.view_name,
        te."desc",
        te.geometry_field,
        te.geometry_srid,
        te.public,
        l.id_licence,
        COALESCE(vpk.view_pk_column, '')
    FROM gn_exports.tmp_exports AS te
        JOIN gn_exports.t_licences AS l
            ON te.name_licence = l.name_licence
        LEFT JOIN view_pk_columns AS vpk
            ON vpk.schema_name = te.schema_name AND vpk.view_name = te.view_name
    WHERE NOT EXISTS (
        SELECT 'TRUE'
        FROM gn_exports.t_exports AS e
        WHERE e.label = te.label
    )
    RETURNING *
)
SELECT count(*) AS inserted_exports
FROM new_exports ;


\echo '----------------------------------------------------------------------------'
\echo 'Migrate exports roles links'

WITH export_role_prefixes AS (
    SELECT DISTINCT
        regexp_replace(er.label_export, '_[0-9]+$', '') AS label_prefix
    FROM gn_exports.tmp_exports_roles AS er
),
export_role_tokens AS MATERIALIZED (
    SELECT
        label_prefix,
        replace(gen_random_uuid()::text, '-', '') AS token
    FROM export_role_prefixes
),
new_exports_roles AS (
    INSERT INTO gn_exports.cor_exports_roles (
        id_export,
        id_role,
        token
    )
    SELECT
        e.id,
        r.id_role,
        ert.token
    FROM gn_exports.tmp_exports_roles AS er
        JOIN gn_exports.t_exports AS e
            ON er.label_export = e.label
        JOIN utilisateurs.t_roles AS r
            ON er.uuid_role = r.uuid_role
        JOIN export_role_tokens AS ert
            ON regexp_replace(er.label_export, '_[0-9]+$', '') IS NOT DISTINCT FROM ert.label_prefix
    RETURNING *
)
SELECT count(*) AS inserted_exports_roles
FROM new_exports_roles ;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is OK:'
COMMIT;
