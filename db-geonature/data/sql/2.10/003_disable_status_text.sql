-- Disable all status text not used for SINP AURA.
-- Required rights: DB OWNER
-- GeoNature database compatibility : v2.6.2+
-- Transfert this script on server this way:
-- rsync -av ./003_* geonat@db-aura-sinp:~/data/db-geonature/data/sql/ --dry-run
-- Use this script this way: psql -h localhost -U geonatadmin -d geonature2db \
--      -f ~/data/db-geonature/data/sql/003_*
-- See: https://github.com/cbn-alpin/sinp-aura-tickets/issues/55
BEGIN;

\echo '----------------------------------------------------------------------------'
\echo 'Disable all status text'
UPDATE taxonomie.bdc_statut_text
SET "enable" = false ;

\echo '----------------------------------------------------------------------------'
\echo 'Enalbe all status text used for SINP AURA territory'
UPDATE taxonomie.bdc_statut_text AS s
SET "enable" = true
FROM taxonomie.bdc_statut_cor_text_area AS ct
    JOIN ref_geo.l_areas AS la
        ON ct.id_area = la.id_area
WHERE s.id_text = ct.id_text
    AND la.id_type = ref_geo.get_id_area_type('DEP')
    AND la.area_code IN ('01', '03', '07', '15', '26', '38', '42', '43', '63', '69', '73', '74')
    AND cd_type_statut IN (
        'LRM', 'LRE', 'LRN', 'LRR', 'ZDET', 'DO', 'DH', 'REGL', 'REGLLUTTE', 'PN', 'PR', 'PD'
    ) ;

\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is OK:'
COMMIT;
