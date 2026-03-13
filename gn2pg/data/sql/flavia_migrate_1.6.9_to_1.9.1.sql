-- Script to migrate from Gn2Pg 1.6.9 to 1.9.1.
-- Run with : psql -h localhost -d <db-name> -f "flavia_migrate_1.6.9_to_1.9.1.sql"

BEGIN;


\echo '-------------------------------------------------------------------------------'
\echo 'Delete entries of data_json table without UUID'

DELETE FROM gn2pg_flavia.data_json WHERE uuid IS NULL ;

\echo '-------------------------------------------------------------------------------'
\echo 'Delete entries of data_json with cd_nom NOT IN TaxRef'

DROP TABLE IF EXISTS gn2pg_flavia.tmp_data_taxref ;

CREATE TABLE gn2pg_flavia.tmp_data_taxref AS
    SELECT
        d.id_data,
        (d.item ->> 'cd_nom')::INT AS cd_nom,
        NULL::bool AS in_taxref
    FROM gn2pg_flavia.data_json AS d
WITH DATA ;

DELETE FROM gn2pg_flavia.tmp_data_taxref WHERE cd_nom IS NULL ;

ALTER TABLE gn2pg_flavia.tmp_data_taxref ADD CONSTRAINT tmp_data_taxref_pk PRIMARY KEY (id_data);

CREATE INDEX tmp_data_taxref_cd_nom_idx ON gn2pg_flavia.tmp_data_taxref (cd_nom);

WITH distinct_cd_nom AS (
    SELECT DISTINCT cd_nom
    FROM gn2pg_flavia.tmp_data_taxref
),
in_taxref AS (
    SELECT d.cd_nom
    FROM distinct_cd_nom AS d
        JOIN taxonomie.taxref AS t
            ON d.cd_nom = t.cd_nom
),
not_in_taxref AS (
    SELECT d.cd_nom
    FROM distinct_cd_nom AS d
        LEFT JOIN in_taxref AS t
            ON t.cd_nom = d.cd_nom
    WHERE t.cd_nom IS NULL
)
UPDATE gn2pg_flavia.tmp_data_taxref
SET in_taxref = FALSE
WHERE cd_nom IN (SELECT cd_nom FROM not_in_taxref) ;

UPDATE gn2pg_flavia.tmp_data_taxref
SET in_taxref = TRUE
WHERE in_taxref IS NULL;

DELETE FROM gn2pg_flavia.data_json
WHERE id_data IN (SELECT id_data FROM gn2pg_flavia.tmp_data_taxref WHERE in_taxref = FALSE) ;

DROP TABLE IF EXISTS gn2pg_flavia.tmp_data_taxref ;

\echo '-------------------------------------------------------------------------------'
\echo 'Add index on uuid for data_json table'

ALTER TABLE ONLY gn2pg_flavia.data_json ADD CONSTRAINT unique_uuid UNIQUE (uuid) ;


\echo '-------------------------------------------------------------------------------'
\echo 'Upgrade tables for Gn2Pg v1.9.1'

SET SESSION_REPLICATION_ROLE TO replica ;

ALTER TABLE gn2pg_flavia.data_json ADD import_id INT
    REFERENCES gn2pg_flavia.import_log
    ON UPDATE CASCADE ;

ALTER TABLE gn2pg_flavia.error_log ADD import_id INT
    REFERENCES gn2pg_flavia.import_log ON
    UPDATE CASCADE ON DELETE CASCADE ;

ALTER TABLE gn2pg_flavia.error_log ADD uuid uuid ;

UPDATE gn2pg_flavia.error_log SET
    uuid = COALESCE(item ->> 'id_perm_sinp', item ->> 'uuid')::uuid ;

ALTER TABLE gn2pg_flavia.error_log ALTER COLUMN uuid SET NOT NULL ;


\echo '-------------------------------------------------------------------------------'
\echo 'Populate import_log table from download/increment_log tables'

WITH history AS (
    SELECT
        source,
        controler,
        download_ts AS xfer_start_ts
    FROM gn2pg_flavia.download_log

    UNION

    SELECT
        source,
        controler,
        last_ts AS xfer_start_ts
    FROM gn2pg_flavia.increment_log
),
hunion AS (
    SELECT
        source,
        controler,
        MAX(xfer_start_ts) AS xfer_start_ts
    FROM history
    GROUP BY source, controler
)
INSERT INTO gn2pg_flavia.import_log (
    source, controler, xfer_type, xfer_status, xfer_start_ts, data_count_upserts, "comment"
)
    SELECT
        hunion.source,
        hunion.controler,
        'full' AS xfer_type,
        'success' AS xfer_status,
        hunion.xfer_start_ts,
        COUNT(data_json.*) AS data_count_upserts,
        'Line generated on upgrade to gn2pg 1.9 or above'
    FROM hunion
        JOIN gn2pg_flavia.data_json
            ON (data_json.source, data_json.controler) = (hunion.source, hunion.controler)
    GROUP BY hunion.source, hunion.controler, hunion.xfer_start_ts
    ORDER BY xfer_start_ts ASC ;


UPDATE gn2pg_flavia.data_json AS dj SET
    import_id = il.id
FROM gn2pg_flavia.import_log AS il
WHERE il.source = dj.source ;

UPDATE gn2pg_flavia.error_log AS el SET
    import_id = il.id
FROM gn2pg_flavia.import_log AS il
WHERE il.source = el.source;

CREATE INDEX tmp_ca_data
    ON gn2pg_flavia.data_json
        ((data_json.item #>> '{ca_data,uuid}'), update_ts);

CREATE INDEX tmp_jdd_data
    ON gn2pg_flavia.data_json
        ((data_json.item #>> '{jdd_data,uuid}'), update_ts);


\echo '-------------------------------------------------------------------------------'
\echo 'Populate metadata_json table'

INSERT INTO gn2pg_flavia.metadata_json(
    uuid, source, controler, type, level, item, import_id, update_ts
)
    SELECT DISTINCT ON (data_json.item #>> '{ca_data,uuid}')
        CAST(data_json.item #>> '{ca_data,uuid}' AS uuid) AS uuid,
        source,
        'metadata' AS controller,
        data_json.type,
        'acquisition framework' AS level,
        item -> 'ca_data' AS ca_data,
        import_id,
        update_ts
    FROM gn2pg_flavia.data_json
    ORDER BY data_json.item #>> '{ca_data,uuid}', update_ts ASC
ON CONFLICT (uuid) DO NOTHING;


INSERT INTO gn2pg_flavia.metadata_json(
    uuid, source, controler, type, level, item, import_id, update_ts
)
    SELECT DISTINCT ON (data_json.item #>> '{jdd_data,uuid}')
        CAST(data_json.item #>> '{jdd_data,uuid}' AS uuid) AS uuid,
        source,
        'metadata' AS controller,
        data_json.type,
        'dataset' AS level,
        item -> 'jdd_data' AS ca_data,
        import_id,
        update_ts
    FROM gn2pg_flavia.data_json
    ORDER BY data_json.item #>> '{jdd_data,uuid}', update_ts ASC
ON CONFLICT (uuid) DO NOTHING;

UPDATE gn2pg_flavia.data_json SET
    item = JSONB_INSERT(
        JSONB_INSERT(((item - 'jdd_data') - 'ca_data'), '{ca_uuid}', item #> '{ca_data,uuid}'),
        '{jdd_uuid}', item #> '{jdd_data,uuid}'
    )
WHERE item ?& ARRAY ['ca_data','jdd_data'];


\echo '-------------------------------------------------------------------------------'
\echo 'Upgrade tables for Gn2Pg v1.9.1 after metadata and log populating'

ALTER TABLE gn2pg_flavia.data_json
    ALTER COLUMN import_id SET NOT NULL;

ALTER TABLE gn2pg_flavia.error_log
    ALTER COLUMN import_id SET NOT NULL;

ALTER TABLE gn2pg_flavia.error_log
    ALTER COLUMN uuid SET NOT NULL;

ALTER TABLE gn2pg_flavia.error_log
    DROP COLUMN id_data;


\echo '----------------------------------------------------------------------------'
\echo 'Drop useless indexes and tables'
DROP INDEX IF EXISTS gn2pg_flavia.tmp_ca_data;
DROP INDEX IF EXISTS gn2pg_flavia.tmp_jdd_data;

DROP TABLE gn2pg_flavia.download_log;
DROP TABLE gn2pg_flavia.increment_log;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;


\echo '----------------------------------------------------------------------------'
\echo 'Vacuum full analyse verbose on gn2pg tables'

VACUUM (FULL, VERBOSE, ANALYZE) gn2pg_flavia.data_json ;
VACUUM (FULL, VERBOSE, ANALYZE) gn2pg_flavia.error_log ;
VACUUM (FULL, VERBOSE, ANALYZE) gn2pg_flavia.import_log ;
VACUUM (FULL, VERBOSE, ANALYZE) gn2pg_flavia.metadata_json ;
