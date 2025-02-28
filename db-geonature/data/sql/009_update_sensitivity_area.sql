-- Update table gn_sensitivity.cor_sensitivity_area_type.
-- Required rights: DB OWNER
-- GeoNature database compatibility : v2.9.2+
--
-- Transfert this script on server with Git or this way:
--      rsync -av ./009_* geonat@db-aura-sinp:~/data/db-geonature/data/sql/ --dry-run
-- Use this script this way:
--      psql -h localhost -U geonatadmin -d geonature2db -f ./009_*
-- Then :
--      - update your "geonature_config.toml" file to set AREA_TYPE_FOR_SENSITIVITY_LEVELS
--        like the values table (retro-compatibility)
--      - activate GeoNature venv
--      - update configuration with : `geonature update-configuration`
--      - restart GeoNature systemd service : `sudo systemctl restart geonature`


BEGIN ;

\echo '----------------------------------------------------------------------------'
\echo 'Delete previous entries'

TRUNCATE gn_sensitivity.cor_sensitivity_area_type ;

\echo '----------------------------------------------------------------------------'
\echo 'Insert new sensitivity values corresponding to area types for SINP AURA'

INSERT INTO gn_sensitivity.cor_sensitivity_area_type
    (id_nomenclature_sensitivity, i_area_type)
VALUES
    (ref_nomenclatures.get_id_nomenclature('SENSIBILITE', '1'), ref_geo.get_id_area_type('M5')),
    (ref_nomenclatures.get_id_nomenclature('SENSIBILITE', '2'), ref_geo.get_id_area_type('M5')),
    (ref_nomenclatures.get_id_nomenclature('SENSIBILITE', '3'), ref_geo.get_id_area_type('M5')),
    (ref_nomenclatures.get_id_nomenclature('SENSIBILITE', '2.1'), ref_geo.get_id_area_type('M1')),
    (ref_nomenclatures.get_id_nomenclature('SENSIBILITE', '2.2'), ref_geo.get_id_area_type('M2')),
    (ref_nomenclatures.get_id_nomenclature('SENSIBILITE', '2.3'), ref_geo.get_id_area_type('M5')),
    (ref_nomenclatures.get_id_nomenclature('SENSIBILITE', '2.4'), ref_geo.get_id_area_type('M10')),
    (ref_nomenclatures.get_id_nomenclature('SENSIBILITE', '2.5'), ref_geo.get_id_area_type('M20')),
    (ref_nomenclatures.get_id_nomenclature('SENSIBILITE', '2.6'), ref_geo.get_id_area_type('M50')),
    (ref_nomenclatures.get_id_nomenclature('SENSIBILITE', '2.7'), ref_geo.get_id_area_type('M50'))
;

\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is OK:'
COMMIT ;
