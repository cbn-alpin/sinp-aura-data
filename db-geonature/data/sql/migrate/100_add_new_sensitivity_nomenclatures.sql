-- Add new sensitivity nomenclature based on meshes for SINP AURA.
-- Required rights: DB OWNER
-- GeoNature database compatibility : v2.9.2+
-- Transfert this script on server this way:
-- rsync -av ./005_* geonat@db-aura-sinp:~/data/db-geonature/data/sql/ --dry-run
-- Use this script this way:
--      cat ./005_* | sed 's#${csvDirectory}#/path/to/db-geonature/csv/directory#g'| \
--      psql -h localhost -U geonatadmin -d geonature2db
BEGIN;

\echo '-------------------------------------------------------------------------------'
\echo 'Set status of old sensitivity nomenclatures to deprecated'
UPDATE ref_nomenclatures.t_nomenclatures SET
    statut = 'Gelé'
WHERE id_type = ref_nomenclatures.get_id_nomenclature_type('SENSIBILITE')
    AND cd_nomenclature IN ('1', '2', '3', '4') ;


\echo '-------------------------------------------------------------------------------'
\echo 'Create temporary nomenclatures import table'
DROP TABLE IF EXISTS gn_imports.sensitivity_nomenclatures ;

CREATE TABLE gn_imports.sensitivity_nomenclatures AS
    SELECT
        NULL::INT AS gid,
        NULL::VARCHAR(255) AS type_nomenclature_code,
        cd_nomenclature,
        mnemonique,
        label_default,
        definition_default,
        label_fr,
        definition_fr,
        source,
        statut,
        NULL::VARCHAR(255) AS cd_nomenclature_broader,
        hierarchy
    FROM ref_nomenclatures.t_nomenclatures
WITH NO DATA ;


\echo '-------------------------------------------------------------------------------'
\echo 'Copy new sensitivity nomenclatures CVS file to temporary import table'
COPY gn_imports.sensitivity_nomenclatures (
    type_nomenclature_code,
    cd_nomenclature,
    mnemonique,
    label_default,
    definition_default,
    label_fr,
    definition_fr,
    source,
    statut,
    cd_nomenclature_broader,
    hierarchy
)
FROM '${csvDirectory}/sensitivity_nomenclatures.csv'
WITH CSV HEADER DELIMITER ',' NULL '\N' ;


\echo '-------------------------------------------------------------------------------'
\echo 'Insert new sensitivity nomenclatures to t_nomenclatures table'
INSERT INTO ref_nomenclatures.t_nomenclatures (
    id_type,
    cd_nomenclature,
    mnemonique,
    label_default,
    definition_default,
    label_fr,
    definition_fr,
    source,
    statut,
    id_broader,
    hierarchy
)
    SELECT
        ref_nomenclatures.get_id_nomenclature_type(type_nomenclature_code),
        cd_nomenclature,
        mnemonique,
        label_default,
        definition_default,
        label_fr,
        definition_fr,
        source,
        statut,
        ref_nomenclatures.get_id_nomenclature(type_nomenclature_code, cd_nomenclature_broader),
        CONCAT(ref_nomenclatures.get_id_nomenclature_type(type_nomenclature_code), hierarchy)
    FROM gn_imports.sensitivity_nomenclatures
ON CONFLICT DO NOTHING ;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is OK:'
COMMIT;

