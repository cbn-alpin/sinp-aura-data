-- Required rights: SUPER USER
-- GeoNature database compatibility : v2.6.0+
-- Fix replacement of reg_geo schema
BEGIN;


\echo '-------------------------------------------------------------------------------'
\echo 'Update constraint "fk_cor_area_synthese_id_area"'
ALTER TABLE gn_synthese.cor_area_synthese DROP CONSTRAINT IF EXISTS fk_cor_area_synthese_id_area ;

ALTER TABLE gn_synthese.cor_area_synthese ADD CONSTRAINT fk_cor_area_synthese_id_area 
    FOREIGN KEY (id_area) REFERENCES ref_geo.l_areas(id_area) ON UPDATE CASCADE ;


\echo '-------------------------------------------------------------------------------'
\echo 'Update constraint "fk_cor_site_area_id_area"'
ALTER TABLE gn_monitoring.cor_site_area DROP CONSTRAINT IF EXISTS fk_cor_site_area_id_area ;

ALTER TABLE gn_monitoring.cor_site_area ADD CONSTRAINT fk_cor_site_area_id_area 
    FOREIGN KEY (id_area) REFERENCES ref_geo.l_areas(id_area) ;


\echo '-------------------------------------------------------------------------------'
\echo 'Update constraint "fk_cor_sensitivity_area_id_area_fkey"'
TRUNCATE TABLE gn_sensitivity.cor_sensitivity_area ;

ALTER TABLE gn_sensitivity.cor_sensitivity_area DROP CONSTRAINT IF EXISTS fk_cor_sensitivity_area_id_area_fkey ;

ALTER TABLE gn_sensitivity.cor_sensitivity_area ADD CONSTRAINT fk_cor_sensitivity_area_id_area_fkey 
    FOREIGN KEY (id_area) REFERENCES ref_geo.l_areas(id_area) ;


\echo '-------------------------------------------------------------------------------'
\echo 'Update constraint "cor_sensitivity_area_type_id_area_type_fkey"'
ALTER TABLE gn_sensitivity.cor_sensitivity_area_type DROP CONSTRAINT IF EXISTS cor_sensitivity_area_type_id_area_type_fkey ;

ALTER TABLE gn_sensitivity.cor_sensitivity_area_type ADD CONSTRAINT cor_sensitivity_area_type_id_area_type_fkey 
    FOREIGN KEY (id_area_type) REFERENCES ref_geo.bib_areas_types(id_type) ;


\echo '----------------------------------------------------------------------------'
\echo 'Add l_areas missing constraint: "unique_id_type_area_code"'
ALTER TABLE ref_geo.l_areas DROP CONSTRAINT IF EXISTS unique_id_type_area_code ;

ALTER TABLE ref_geo.l_areas ADD CONSTRAINT unique_id_type_area_code UNIQUE (id_type, area_code) ;


\echo '----------------------------------------------------------------------------'
\echo 'Add bib_areas_types missing constraint: "unique_bib_areas_types_type_code"'
ALTER TABLE ref_geo.bib_areas_types DROP CONSTRAINT IF EXISTS unique_bib_areas_types_type_code ;

ALTER TABLE ref_geo.bib_areas_types ADD CONSTRAINT unique_bib_areas_types_type_code UNIQUE (type_code) ;


\echo '-------------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;