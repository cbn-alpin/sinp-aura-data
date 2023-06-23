\echo 'Fix unique_id_grp_releve and nomenclature_bio_condition in synthese table.'
\echo 'Rights: db-owner'
\echo 'GeoNature database compatibility : v2.6.2+'
-- Usage: psql -h "localhost" -U "<db-owner-name>" -d "<db-name>" -f <path-to-this-sql-file>
-- Ex.: psql -h "localhost" -U "geonatadmin" -d "geonature2db" -f ~/data/lpo/data/sql/fix/002_*

BEGIN;


SET client_encoding = 'UTF8';


\echo '-------------------------------------------------------------------------------'
\echo 'Move table diff_on_old_data_2023030 from gn_synthese schema to gn_imports'
ALTER TABLE IF EXISTS gn_synthese.diff_on_old_data_20230309 SET SCHEMA gn_imports;


\echo '-------------------------------------------------------------------------------'
\echo 'Disable trigger "tri_meta_dates_change_synthese"'
ALTER TABLE gn_synthese.synthese DISABLE TRIGGER tri_meta_dates_change_synthese ;


\echo '-------------------------------------------------------------------------------'
\echo 'Disable trigger "tri_update_calculate_sensitivity"'
ALTER TABLE gn_synthese.synthese DISABLE TRIGGER tri_update_calculate_sensitivity ;

\echo '----------------------------------------------------------------------------'
\echo 'Update unique_id_sinp_grp and cd_nomenclature_bio_condition'
UPDATE gn_synthese.synthese
SET unique_id_sinp_grp = newdata.unique_id_sinp_grp,
    id_nomenclature_bio_condition = ref_nomenclatures.get_id_nomenclature('ETA_BIO', newdata.cd_nomenclature_bio_condition)
FROM gn_imports.diff_on_old_data_20230309 AS newdata
WHERE newdata.unique_id_sinp = synthese.unique_id_sinp;


\echo '-------------------------------------------------------------------------------'
\echo 'Enable trigger "tri_meta_dates_change_synthese"'
ALTER TABLE gn_synthese.synthese ENABLE TRIGGER tri_meta_dates_change_synthese ;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
