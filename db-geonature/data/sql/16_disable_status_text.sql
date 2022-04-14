-- Disable all status text not used for SINP AURA.
-- Required rights: DB OWNER
-- GeoNature database compatibility : v2.6.2+
-- Transfert this script on server this way:
-- rsync -av ./16_* geonat@db-aura-sinp:~/data/db-geonature/data/sql/ --dry-run
-- Use this script this way: psql -h localhost -U geonatadmin -d geonature2db \
--      -f ~/data/db-geonature/data/sql/16_*
-- See: https://github.com/cbn-alpin/sinp-paca-tickets/issues/182
BEGIN;

\echo '----------------------------------------------------------------------------'
\echo 'Disable all status text not used for SINP PACA territory'
UPDATE taxonomie.bdc_statut_text
SET enable = false
WHERE (
        cd_doc IS NULL
        OR cd_doc NOT IN (
            625, 633, 643, 691, 692, 703, 713, 716, 730, 731, 738, 755, 756, 758, 763, 901, 3561,
            3601, 3622, 3661, 3681, 158248, 161768, 161848, 161968, 162008, 162474, 179483, 179650,
            192208, 194588, 194589, 194608, 195168, 196448, 215830, 233229, 264852, 265589, 268429,
            319830, 324909, 324929, 358269, 358270, 366749
        )
    )
    AND lb_adm_tr IN (
        'France', 'France métropolitaine',
        'Auvergne', 'Rhône-Alpes',
        'Ain', 'Allier', 'Ardèche', 'Cantal', 'Drôme', 'Haute-Loire',
        'Haute-Savoie', 'Isère', 'Loire',  'Puy-de-Dôme', 'Rhône', 'Savoie',
        ''
    ) ;

\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is OK:'
COMMIT;
