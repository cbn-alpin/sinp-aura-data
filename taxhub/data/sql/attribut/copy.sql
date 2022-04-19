BEGIN;

\echo '-------------------------------------------------------------------------------'
\echo 'Copy CSV data into gn_imports schema and TaxHub attributs table.'
\echo 'Rights: superuser'
\echo 'GeoNature database compatibility : v2.4.1'

SET client_encoding = 'UTF8';


\echo '-------------------------------------------------------------------------------'
\echo 'Remove imports attributs table if already exists'
DROP TABLE IF EXISTS gn_imports.:attributImportTable ;


\echo '-------------------------------------------------------------------------------'
\echo 'Create imports attributs table from "bib_attributs" with additional fields'
CREATE TABLE gn_imports.:attributImportTable AS
    SELECT
        NULL::INT AS gid,
        nom_attribut AS code,
        label_attribut AS label,
        liste_valeur_attribut AS "values",
        obligatoire AS mandatory,
        desc_attribut AS "description",
        type_attribut AS "type",
        type_widget AS widget,
        id_theme AS theme_code,
        ordre AS order
    FROM taxonomie.bib_attributs
WITH NO DATA ;


\echo '-------------------------------------------------------------------------------'
\echo 'Add primary key on imports attributs table'
\set importTablePk 'pk_':attributImportTable
ALTER TABLE gn_imports.:attributImportTable
	ALTER COLUMN gid ADD GENERATED ALWAYS AS IDENTITY,
	ADD CONSTRAINT :importTablePk PRIMARY KEY(gid);


\echo '-------------------------------------------------------------------------------'
\echo 'Create indexes on imports attributs table'
\set codeIdx 'idx_unique_':attributImportTable'_code'
CREATE UNIQUE INDEX :codeIdx
    ON gn_imports.:attributImportTable USING btree (code);


\echo '-------------------------------------------------------------------------------'
\echo 'Attribute imports attributs table to GeoNature DB owner'
ALTER TABLE gn_imports.:attributImportTable OWNER TO :gnDbOwner ;


\echo '-------------------------------------------------------------------------------'
\echo 'Copy CVS file to import attributs table'
COPY gn_imports.:attributImportTable (
    code,
    label,
    "values",
    mandatory,
    "description",
    "type",
    widget,
    theme_code,
    "order"
)
FROM :'csvFilePath'
WITH CSV HEADER DELIMITER E'\t' NULL '\N' ;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
