-- Update Synthese data without Gn2Pg for "Pôle Vertébrés"
-- Required rights: DB OWNER
-- GeoNature database compatibility : v2.9.2+
--
-- Transfert this script on server with Git or this way (remove --dry-run if it's OK):
--      rsync -av ./018_* geonat@db-aura-sinp:~/data/db-geonature/data/sql/ --dry-run
-- Download CSV file in geonat@db-aura-sinp:~/data/db-geonature/data/csv/ with :
--      sftp -oPort=<poty-sftp> geonat@<host>:/lpo/2026-01-26_pole_vert_update.csv.gz /home/geonat/data/db-geonature/data/csv
-- Unzip with : gunzip 2026-01-26_pole_vert_update.csv.gz
-- Launch a Byobu or Screen session : byobu
-- Use this script this way:
--      psql -h localhost -U geonatadmin -d geonature2db \
--          -v csvFilePath=/home/geonat/data/db-geonature/data/csv/2026-01-26_pole_vert_update.csv \
--          -f ./019_*

\echo '-------------------------------------------------------------------------------'
\echo 'Create the table for the update (destination database)'

DROP TABLE IF EXISTS gn2pg_lpo.tmp_update_2026_01 ;

CREATE TABLE gn2pg_lpo.tmp_update_2026_01 (
    id_perm_sinp UUID,
    observateurs TEXT,
    determinateur TEXT,
    comment_occurence TEXT
) ;

CREATE INDEX ON gn2pg_lpo.tmp_update_2026_01(id_perm_sinp) ;

\echo '-------------------------------------------------------------------------------'
\echo 'Import data to temporary table'

COPY gn2pg_lpo.tmp_update_2026_01 FROM :'csvFilePath' WITH csv header ;


\echo '-------------------------------------------------------------------------------'
\echo 'Update data in synthese'

BEGIN ;

\echo 'Disable trigger "tri_meta_dates_change_synthese"'
ALTER TABLE gn_synthese.synthese DISABLE TRIGGER tri_insert_calculate_sensitivity ;
ALTER TABLE gn_synthese.synthese DISABLE TRIGGER tri_insert_cor_area_synthese ;
ALTER TABLE gn_synthese.synthese DISABLE TRIGGER tri_meta_dates_change_synthese ;
ALTER TABLE gn_synthese.synthese DISABLE TRIGGER tri_update_calculate_sensitivity ;
ALTER TABLE gn_synthese.synthese DISABLE TRIGGER tri_update_cor_area_synthese ;

\echo 'Update synthese...'
UPDATE gn_synthese.synthese AS s SET
    observers = tmp.observateurs,
    determiner = tmp.determinateur,
    comment_description = tmp.comment_occurence
FROM gn2pg_lpo.tmp_update_2026_01 AS tmp
    WHERE tmp.id_perm_sinp = s.unique_id_sinp ;

\echo 'Drop useless temporary table...'
DROP TABLE IF EXISTS gn2pg_lpo.tmp_update_2026_01 ;

\echo 'Enable trigger "tri_meta_dates_change_synthese"'
ALTER TABLE gn_synthese.synthese ENABLE TRIGGER tri_insert_calculate_sensitivity ;
ALTER TABLE gn_synthese.synthese ENABLE TRIGGER tri_insert_cor_area_synthese ;
ALTER TABLE gn_synthese.synthese ENABLE TRIGGER tri_meta_dates_change_synthese ;
ALTER TABLE gn_synthese.synthese ENABLE TRIGGER tri_update_calculate_sensitivity ;
ALTER TABLE gn_synthese.synthese ENABLE TRIGGER tri_update_cor_area_synthese ;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is OK:'
COMMIT ;
