-- Script to import CBNA raw synthese data
-- Usage: psql -h localhost -U geonatadmin -d geonaturedb -v syntheseCSV="<path-to-synthese-csv>" -f synthese_raw_import.sql

DROP TABLE IF EXISTS raw_cbna_synthese ;

CREATE TABLE raw_cbna_synthese (
    gid int4 GENERATED ALWAYS AS IDENTITY( INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START 1 CACHE 1 NO CYCLE) NOT NULL,
    unique_id_sinp varchar(50) NULL,
    unique_id_sinp_grp varchar(50) NULL,
    source_id varchar(25) NULL,
    source_id_grp varchar(25) NULL,
    code_source varchar(255) NOT NULL,
    code_dataset varchar(255) NOT NULL,
    code_module varchar(255) NULL, -- Absent
    code_nomenclature_geo_object_nature varchar(50) NULL,
    code_nomenclature_grp_typ varchar(25) NULL,
    grp_method varchar(255) NULL,
    code_nomenclature_obs_technique varchar(50) NULL,
    code_nomenclature_bio_status varchar(50) NULL,
    code_nomenclature_bio_condition varchar(50) NULL,
    code_nomenclature_naturalness varchar(50) NULL,
    code_nomenclature_exist_proof varchar(50) NULL,
    code_nomenclature_valid_status varchar(50) NULL,
    code_nomenclature_diffusion_level varchar(50) NULL,
    code_nomenclature_life_stage varchar(50) NULL,
    code_nomenclature_sex varchar(50) NULL,
    code_nomenclature_obj_count varchar(50) NULL,
    code_nomenclature_type_count varchar(50) NULL,
    code_nomenclature_sensitivity varchar(50) NULL,
    code_nomenclature_observation_status varchar(50) NULL,
    code_nomenclature_blurring varchar(50) NULL,
    code_nomenclature_source_status varchar(50) NULL,
    code_nomenclature_info_geo_type varchar(50) NULL,
    code_nomenclature_behaviour varchar(50) NULL,
    code_nomenclature_biogeo_status varchar(50) NULL,
    reference_biblio varchar(5000) NULL,
    count_min varchar(25) NULL,
    count_max varchar(25) NULL,
    cd_nom varchar(25) NULL,
    cd_hab varchar(25) NULL, -- Absent
    nom_cite varchar(1000) NULL,
    meta_v_taxref varchar(50) NULL, -- Absent
    sample_number_proof text NULL, -- Absent
    digital_proof text NULL,
    non_digital_proof text NULL, -- Absent
    altitude_min varchar(25) NULL,
    altitude_max varchar(25) NULL,
    depth_min varchar(25) NULL,
    depth_max varchar(25) NULL,
    place_name varchar(500) NULL,
    geom text NULL,
    "precision" varchar(25) NULL,
    code_area_attachment varchar(25) NULL, -- Absent
    date_min varchar(50) NULL,
    date_max varchar(50) NULL,
    "validator" varchar(1000) NULL,
    validation_comment text NULL,
    validation_date varchar(50) NULL,
    observers varchar(1000) NULL,
    determiner varchar(1000) NULL,
    determination_date varchar(50) NULL,
    code_digitiser varchar(250) NULL,
    code_nomenclature_determination_method varchar(50) NULL,
    comment_context text NULL,
    comment_description text NULL,
    additional_data JSONB NULL,
    meta_create_date varchar(50) NULL,
    meta_update_date varchar(50) NULL,
    meta_last_action bpchar(1) NULL,
    CONSTRAINT pk_raw_cbna_synthese PRIMARY KEY (gid)
);

COPY raw_cbna_synthese (
    unique_id_sinp,
    unique_id_sinp_grp,
    source_id,
    source_id_grp,
    code_source,
    code_dataset,
    code_nomenclature_geo_object_nature,
    code_nomenclature_grp_typ,
    grp_method,
    code_nomenclature_obs_technique,
    code_nomenclature_bio_status,
    code_nomenclature_bio_condition,
    code_nomenclature_naturalness,
    code_nomenclature_exist_proof,
    code_nomenclature_valid_status,
    code_nomenclature_diffusion_level,
    code_nomenclature_life_stage,
    code_nomenclature_sex,
    code_nomenclature_obj_count,
    code_nomenclature_type_count,
    code_nomenclature_sensitivity,
    code_nomenclature_observation_status,
    code_nomenclature_blurring,
    code_nomenclature_source_status,
    code_nomenclature_info_geo_type,
    code_nomenclature_behaviour,
    code_nomenclature_biogeo_status,
    reference_biblio,
    count_min,
    count_max,
    cd_nom,
    nom_cite,
    digital_proof,
    altitude_min,
    altitude_max,
    depth_min,
    depth_max,
    place_name,
    geom,
    "precision",
    -- code_area_attachment, -- maybe not present
    date_min,
    date_max,
    "validator",
    validation_comment,
    validation_date,
    observers,
    determiner,
    determination_date,
    code_digitiser,
    code_nomenclature_determination_method,
    comment_context,
    comment_description,
    additional_data,
    meta_create_date,
    meta_update_date,
    meta_last_action
)
FROM :'syntheseCsv'
WITH CSV HEADER DELIMITER E'\t' ;

UPDATE raw_cbna_synthese SET
    code_area_attachment = CASE
        WHEN (additional_data ->> 'communeInseeCode') IS NOT NULL THEN CONCAT('COM.', CAST(additional_data ->> 'communeInseeCode' AS text))
        WHEN (additional_data ->> 'departementInseeCode') IS NOT NULL THEN CONCAT('DEP.', CAST(additional_data ->> 'departementInseeCode' AS text))
        ELSE NULL
    END
WHERE code_nomenclature_info_geo_type = '2' ;

ALTER TABLE raw_cbna_synthese ALTER COLUMN additional_data TYPE text ;

UPDATE raw_cbna_synthese SET code_area_attachment = '\N'
WHERE code_area_attachment IS NULL ;