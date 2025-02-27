--
\echo '-------------------------------------------------------------------------------'
\echo 'Script to update "BDC Statuts" taxonomy in Biodiv Territory tables'
\echo 'GeoNature database compatibility : v2.4.1'
BEGIN;

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
        tx.nom_vern AS nom_francais_cite
    FROM linkage
        LEFT JOIN taxonomie.taxref AS tx
            ON linkage.cd_ref = tx.cd_nom
)
-- mise à jour
UPDATE taxonomie.taxref_protection_especes SET
    cd_nom = patchs.cd_nom,
    nom_cite = patchs.cd_nom,
    nom_francais_cite = patchs.nom_francais_cite
FROM patchs
WHERE taxref_protection_especes.cd_nom = patchs.cd_nom_old ;

\echo '-------------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
