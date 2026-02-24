-- Migrate to GeoNature v2.16/2.17
-- Clean all necessary tables before migration

BEGIN;

\echo '----------------------------------------------------------------------------'
\echo 'Truncate ref_geo tables and their linked tables'
TRUNCATE
    gn_synthese.cor_observer_synthese, -- empty
    gn_synthese.t_reports, -- empty
    gn_synthese.synthese, -- empty
    gn_synthese.cor_area_synthese, -- empty
    gn_monitoring.cor_site_area, -- empty
    gn_sensitivity.cor_sensitivity_area, -- empty
    gn_sensitivity.cor_sensitivity_area_type, --empty
    gn_imports.t_imports_synthese, -- empty
    gn_permissions.cor_permission_area, -- empty
    taxonomie.bdc_statut_cor_text_area, -- Reload by SQL script 004
    ref_geo.cor_linear_area, --empty
    ref_geo.cor_areas, --empty
    ref_geo.li_grids, -- Reload with CSV export file
    ref_geo.li_municipalities, -- Reload with CSV export file
    ref_geo.l_areas, -- Reload with CSV export file
    ref_geo.bib_areas_types -- Reload with CSV export file
;


\echo '----------------------------------------------------------------------------'
\echo 'Reset all sequences of database'

SELECT
    substring(column_default, '''(.*)'''),
    reset_sequence(table_schema, table_name, column_name, substring(column_default, '''(.*)'''))
FROM information_schema.columns
WHERE column_default LIKE 'nextval%' ;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is OK:'
COMMIT ;
