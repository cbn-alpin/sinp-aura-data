--
\echo '-------------------------------------------------------------------------------'
\echo 'Script to update "BDC Statuts" taxonomy in Biodiv Territory tables'
\echo 'GeoNature database compatibility : v2.4.1'
BEGIN;

\echo '-------------------------------------------------------------------------------'
\echo 'Delete constraint on taxref_protection_especes'
ALTER TABLE taxonomie.taxref_protection_especes DROP CONSTRAINT taxref_protection_especes_pkey ;


\echo '-------------------------------------------------------------------------------'
\echo 'Update taxref_protection_especes taxonomy => duplicate rows'
-- Get valid cd_nom
WITH linkage AS (
    SELECT
        tpe.cd_nom AS cd_nom_old,
        tx.cd_ref
    FROM taxonomie.taxref_protection_especes AS tpe
        LEFT JOIN taxonomie.taxref AS tx
            ON tpe.cd_nom = tx.cd_nom
),
-- Retrieve new data from old cd_nom
patchs AS (
    SELECT DISTINCT
        linkage.cd_nom_old,
        tx.cd_nom,
        tx.lb_nom AS nom_cite,
        SPLIT_PART(tx.nom_vern, ', ', 1) AS nom_francais_cite
    FROM linkage
        JOIN taxonomie.taxref AS tx
            ON linkage.cd_ref = tx.cd_nom
)
-- Run the update
UPDATE taxonomie.taxref_protection_especes SET
    cd_nom = patchs.cd_nom,
    nom_cite = patchs.nom_cite,
    nom_francais_cite = patchs.nom_francais_cite
FROM patchs
WHERE taxref_protection_especes.cd_nom = patchs.cd_nom_old ;

\echo '-------------------------------------------------------------------------------'
\echo 'Add a temporary unique primarykey column on taxref_protection_especes'
ALTER TABLE taxonomie.taxref_protection_especes
ADD COLUMN gid INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY;

\echo '-------------------------------------------------------------------------------'
\echo 'Keep only one row for duplicate rows'
DELETE FROM taxonomie.taxref_protection_especes AS tpe1
USING taxonomie.taxref_protection_especes AS tpe2
WHERE tpe1.gid < tpe2.gid
	AND tpe1.cd_nom = tpe2.cd_nom
	AND tpe1.cd_protection = tpe2.cd_protection
	AND tpe1.cd_nom_cite = tpe2.cd_nom_cite ;

\echo '-------------------------------------------------------------------------------'
\echo 'Delete temporary unique primarykey column from taxref_protection_especes'
ALTER TABLE taxonomie.taxref_protection_especes
DROP COLUMN gid ;

\echo '-------------------------------------------------------------------------------'
\echo 'Restore the original constraint on taxref_protection_especes'
ALTER TABLE taxonomie.taxref_protection_especes
ADD CONSTRAINT taxref_protection_especes_pkey PRIMARY KEY (cd_nom, cd_protection, cd_nom_cite) ;

\echo '-------------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
