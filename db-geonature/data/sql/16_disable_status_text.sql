-- Disable all status text not used for SINP AURA.
-- Required rights: DB OWNER
-- GeoNature database compatibility : v2.6.2+
-- Transfert this script on server this way:
-- rsync -av ./04_* geonat@db-aura-sinp:~/data/db-geonature/data/sql/ --dry-run
-- Use this script this way: psql -h localhost -U geonatadmin -d geonature2db \
--      -f ~/data/db-geonature/data/sql/04_*
-- See: https://github.com/cbn-alpin/sinp-paca-tickets/issues/182
BEGIN;

\echo '----------------------------------------------------------------------------'
\echo 'Disable all status text not used for SINP PACA territory'
UPDATE taxonomie.bdc_statut_text
SET enable = false
WHERE cd_doc NOT IN (

) ;

\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is OK:'
COMMIT;
