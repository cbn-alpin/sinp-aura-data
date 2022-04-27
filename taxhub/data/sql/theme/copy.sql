BEGIN;

\echo '-------------------------------------------------------------------------------'
\echo 'Copy CSV data into gn_imports schema and TaxHub theme table.'
\echo 'Rights: superuser'
\echo 'GeoNature database compatibility : v2.4.1'

SET client_encoding = 'UTF8';


\echo '-------------------------------------------------------------------------------'
\echo 'Remove imports themes table if already exists'
DROP TABLE IF EXISTS gn_imports.:themeImportTable ;


\echo '-------------------------------------------------------------------------------'
\echo 'Create imports themes table from "bib_themes" with additional fields'
CREATE TABLE gn_imports.:themeImportTable AS
    SELECT
        NULL::INT AS gid,
        nom_theme AS code,
        desc_theme AS "description"
    FROM taxonomie.bib_themes
WITH NO DATA ;


\echo '-------------------------------------------------------------------------------'
\echo 'Add primary key on imports themes table'
\set importTablePk 'pk_':themeImportTable
ALTER TABLE gn_imports.:themeImportTable
	ALTER COLUMN gid ADD GENERATED ALWAYS AS IDENTITY,
	ADD CONSTRAINT :importTablePk PRIMARY KEY(gid);


\echo '-------------------------------------------------------------------------------'
\echo 'Create indexes on imports themes table'
\set codeIdx 'idx_unique_':themeImportTable'_code'
CREATE UNIQUE INDEX :codeIdx
    ON gn_imports.:themeImportTable USING btree (code);


\echo '-------------------------------------------------------------------------------'
\echo 'Attribute imports themes to GeoNature DB owner'
ALTER TABLE gn_imports.:themeImportTable OWNER TO :gnDbOwner ;


\echo '-------------------------------------------------------------------------------'
\echo 'Copy CVS file to import themes table'
COPY gn_imports.:themeImportTable (
    code,
    "description"
)
FROM :'csvFilePath'
WITH CSV HEADER DELIMITER E'\t' NULL '\N' ;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
