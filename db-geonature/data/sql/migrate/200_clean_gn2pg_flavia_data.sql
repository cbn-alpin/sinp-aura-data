-- Script to clean Flavia Gn2Pg data.

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


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'

COMMIT;

\echo '----------------------------------------------------------------------------'
\echo 'Vacuum full analyse verbose on gn2pg tables'

VACUUM (FULL, VERBOSE, ANALYZE) gn2pg_flavia.data_json ;
VACUUM (FULL, VERBOSE, ANALYZE) gn2pg_flavia.error_log ;
VACUUM (FULL, VERBOSE, ANALYZE) gn2pg_flavia.import_log ;
VACUUM (FULL, VERBOSE, ANALYZE) gn2pg_flavia.metadata_json ;
