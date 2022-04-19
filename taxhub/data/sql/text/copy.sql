BEGIN;

\echo '-------------------------------------------------------------------------------'
\echo 'Copy CSV data into gn_imports schema and TaxHub attributs-taxons-values table.'
\echo 'Rights: superuser'
\echo 'GeoNature database compatibility : v2.4.1'

SET client_encoding = 'UTF8';


\echo '-------------------------------------------------------------------------------'
\echo 'Remove imports attributs-taxons-values table if already exists'
DROP TABLE IF EXISTS gn_imports.:textImportTable ;


\echo '-------------------------------------------------------------------------------'
\echo 'Create imports attributs-taxons-values table from "cor_taxon_attribut" with additional fields'
CREATE TABLE gn_imports.:textImportTable AS
    SELECT
        NULL::INT AS gid,
        cd_ref,
        id_attribut,
        valeur_attribut AS "value"
    FROM taxonomie.cor_taxon_attribut
WITH NO DATA ;


\echo '-------------------------------------------------------------------------------'
\echo 'Add primary key on imports attributs-taxons-values table'
\set importTablePk 'pk_':textImportTable
ALTER TABLE gn_imports.:textImportTable
	ALTER COLUMN gid ADD GENERATED ALWAYS AS IDENTITY,
	ADD CONSTRAINT :importTablePk PRIMARY KEY(gid);


\echo '-------------------------------------------------------------------------------'
\echo 'Create indexes on imports attributs-taxons-values table'
\set codeIdx 'idx_unique_':textImportTable'_cd_ref_id_attribut'
CREATE UNIQUE INDEX :codeIdx
    ON gn_imports.:textImportTable USING btree (cd_ref, id_attribut);


\echo '-------------------------------------------------------------------------------'
\echo 'Attribute imports attributs-taxons-values table to GeoNature DB owner'
ALTER TABLE gn_imports.:textImportTable OWNER TO :gnDbOwner ;


\echo '-------------------------------------------------------------------------------'
\echo 'Copy CVS file to import attributs-taxons-values table'
COPY gn_imports.:textImportTable (
    cd_ref,
    id_attribut,
    "value"
)
FROM :'csvFilePath'
WITH CSV HEADER DELIMITER E'\t' NULL '\N' ;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
