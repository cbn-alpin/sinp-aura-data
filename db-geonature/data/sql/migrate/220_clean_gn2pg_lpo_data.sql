-- Script to clean LPO Gn2Pg data.

BEGIN;


\echo '-------------------------------------------------------------------------------'
\echo 'Add on UPDATE to the Gn2Pg metadata trigger for the LPO metadata'

\echo 'Drop old trigger "tri_c_upsert_metadata_to_geonature"'
DROP TRIGGER IF EXISTS tri_c_upsert_metadata_to_geonature ON gn2pg_lpo.metadata_json ;

\echo 'Create new trigger "tri_c_upsert_metadata_to_geonature"'
CREATE TRIGGER tri_c_upsert_metadata_to_geonature
AFTER INSERT OR UPDATE ON gn2pg_lpo.metadata_json
FOR EACH ROW EXECUTE FUNCTION gn2pg_lpo.fct_tri_upsert_metadata_to_geonature() ;

\echo 'Disable new trigger "tri_c_upsert_metadata_to_geonature" for corrections'
ALTER TABLE gn2pg_lpo.metadata_json DISABLE TRIGGER tri_c_upsert_metadata_to_geonature ;


\echo '-------------------------------------------------------------------------------'
\echo 'Fix metadata organisms name'

UPDATE gn2pg_lpo.metadata_json
SET item = jsonb_set(
    item,
    '{actors}',
    (
        SELECT COALESCE(jsonb_agg(actor ORDER BY ord), '[]'::jsonb)
        FROM jsonb_array_elements(item->'actors') WITH ORDINALITY AS arr(actor, ord)
        WHERE actor->>'uuid_actor' != '101358ba-aaf5-4c3f-8b16-bfd865116b44'
    )
)
WHERE item @> '{"actors": [{"uuid_actor": "101358ba-aaf5-4c3f-8b16-bfd865116b44"}]}'
AND "uuid" = '79e9809a-03b8-4158-a356-646968fc9349' ;


\echo '-------------------------------------------------------------------------------'
\echo 'Fix metadata ca_uuid in item field'

CREATE TABLE gn2pg_lpo.fix_af_uuid (
    d_uuid uuid NULL,
    af_uuid uuid NULL
);

COPY gn2pg_lpo.fix_af_uuid (d_uuid, af_uuid)
FROM '${rawDirectory}/gn2pg_lpo_fix_af_uuid.csv'
WITH (FORMAT csv, HEADER true, DELIMITER E'\t');

UPDATE gn2pg_lpo.metadata_json AS m
SET item = m.item || jsonb_build_object('ca_uuid', f.af_uuid)
FROM gn2pg_lpo.fix_af_uuid AS f
WHERE m.uuid = f.d_uuid
    AND m.level = 'dataset'
    AND NOT (m.item ? 'ca_uuid');


\echo '-------------------------------------------------------------------------------'
\echo 'Enable new trigger "tri_c_upsert_metadata_to_geonature"'
ALTER TABLE gn2pg_lpo.metadata_json ENABLE TRIGGER tri_c_upsert_metadata_to_geonature ;


\echo '-------------------------------------------------------------------------------'
\echo 'Delete entries of data_json table without UUID'

DELETE FROM gn2pg_lpo.data_json WHERE uuid IS NULL ;


\echo '-------------------------------------------------------------------------------'
\echo 'Delete entries of data_json with cd_nom NOT IN TaxRef'

DROP TABLE IF EXISTS gn2pg_lpo.tmp_data_taxref ;

CREATE TABLE gn2pg_lpo.tmp_data_taxref AS
    SELECT
        d.id_data,
        (d.item ->> 'cd_nom')::INT AS cd_nom,
        NULL::bool AS in_taxref
    FROM gn2pg_lpo.data_json AS d
WITH DATA ;

DELETE FROM gn2pg_lpo.tmp_data_taxref WHERE cd_nom IS NULL ;

ALTER TABLE gn2pg_lpo.tmp_data_taxref ADD CONSTRAINT tmp_data_taxref_pk PRIMARY KEY (id_data);

CREATE INDEX tmp_data_taxref_cd_nom_idx ON gn2pg_lpo.tmp_data_taxref (cd_nom);

WITH distinct_cd_nom AS (
    SELECT DISTINCT cd_nom
    FROM gn2pg_lpo.tmp_data_taxref
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
UPDATE gn2pg_lpo.tmp_data_taxref
SET in_taxref = FALSE
WHERE cd_nom IN (SELECT cd_nom FROM not_in_taxref) ;

UPDATE gn2pg_lpo.tmp_data_taxref
SET in_taxref = TRUE
WHERE in_taxref IS NULL;

DELETE FROM gn2pg_lpo.data_json
WHERE id_data IN (SELECT id_data FROM gn2pg_lpo.tmp_data_taxref WHERE in_taxref = FALSE) ;

DROP TABLE IF EXISTS gn2pg_lpo.tmp_data_taxref ;

\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'

COMMIT;

\echo '----------------------------------------------------------------------------'
\echo 'Vacuum full analyse verbose on gn2pg tables'

VACUUM (FULL, VERBOSE, ANALYZE) gn2pg_lpo.data_json ;
VACUUM (FULL, VERBOSE, ANALYZE) gn2pg_lpo.error_log ;
VACUUM (FULL, VERBOSE, ANALYZE) gn2pg_lpo.import_log ;
VACUUM (FULL, VERBOSE, ANALYZE) gn2pg_lpo.metadata_json ;
