BEGIN;

\echo '-------------------------------------------------------------------------------'
\echo 'Copy CSV data into gn_imports schema and TaxHub media table.'
\echo 'Rights: superuser'
\echo 'GeoNature database compatibility : v2.4.1'

SET client_encoding = 'UTF8';


\echo '-------------------------------------------------------------------------------'
\echo 'Remove imports media table if already exists'
DROP TABLE IF EXISTS gn_imports.:mediaImportTable ;


\echo '-------------------------------------------------------------------------------'
\echo 'Create imports media table from "t_medias" with additional fields'
CREATE TABLE gn_imports.:mediaImportTable AS
    SELECT
        NULL::INT AS gid,
        cd_ref,
        titre AS title,
        "url",
        chemin AS "path",
        auteur AS author,
        desc_media AS "description",
        date_media AS "date",
        source,
        licence
    FROM taxonomie.t_medias
WITH NO DATA ;


\echo '-------------------------------------------------------------------------------'
\echo 'Add primary key on imports media table'
\set importTablePk 'pk_':mediaImportTable
ALTER TABLE gn_imports.:mediaImportTable
	ALTER COLUMN gid ADD GENERATED ALWAYS AS IDENTITY,
	ADD CONSTRAINT :importTablePk PRIMARY KEY(gid);


\echo '-------------------------------------------------------------------------------'
\echo 'Create indexes on imports media table'
\set codeIdx 'idx_unique_':mediaImportTable'_url'
CREATE UNIQUE INDEX :codeIdx
    ON gn_imports.:mediaImportTable USING btree ("url");


\echo '-------------------------------------------------------------------------------'
\echo 'Attribute imports media table to GeoNature DB owner'
ALTER TABLE gn_imports.:mediaImportTable OWNER TO :gnDbOwner ;


\echo '-------------------------------------------------------------------------------'
\echo 'Copy CVS file to import media table'
COPY gn_imports.:mediaImportTable (
    cd_ref,
    title,
    "url",
    author,
    "description",
    "date",
    source,
    licence
)
FROM :'csvFilePath'
WITH CSV HEADER DELIMITER E'\t' NULL '\N' ;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
