-- Delete cor_area_synthese entries when id_synthese not exists in synthese table.
-- Required rights: DB OWNER
-- GeoNature database compatibility : v2.6.0+
-- Transfert this script on server this way:
-- rsync -av ./015_* geonat@db-aura-sinp:~/data/db-geonature/data/sql/fix/ --dry-run
-- Use this script this way: psql -h localhost -U geonatadmin -d geonature2db \
--      -f ~/data/db-geonature/data/sql/fix/015_*
BEGIN;

\echo '-------------------------------------------------------------------------------'
\echo 'Remove unused cor_area_synthese entries'

DELETE FROM gn_synthese.cor_area_synthese AS cas
WHERE NOT EXISTS (
    SELECT 'X'
    FROM gn_synthese.synthese AS s
    WHERE s.id_synthese = cas.id_synthese
) ;


\echo '-------------------------------------------------------------------------------'
\echo 'Restore constraint with on delete cascade on cor_area_synthese table'
ALTER TABLE gn_synthese.cor_area_synthese ADD CONSTRAINT fk_cor_area_synthese_id_synthese
FOREIGN KEY (id_synthese) REFERENCES gn_synthese.synthese(id_synthese)
ON UPDATE CASCADE ON DELETE CASCADE ;


\echo '-------------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
