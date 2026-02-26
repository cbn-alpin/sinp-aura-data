-- Migrate to GeoNature v2.16/2.17
-- Clean all necessary tables before migration in destination db

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
    taxonomie.bdc_statut_cor_text_area, -- DATA: Reload by SQL script 004
    ref_geo.cor_linear_area, --empty
    ref_geo.cor_areas, --empty
    ref_geo.li_grids, -- DATA: Reload with CSV export file + SQL script 000b_...
    ref_geo.li_municipalities, -- DATA: Reload with CSV export file
    ref_geo.l_areas, -- DATA: Reload with CSV export file
    ref_geo.bib_areas_types -- DATA: Reload with CSV export file
;


\echo '----------------------------------------------------------------------------'
\echo 'Truncate utilisateurs tables and their linked tables'
TRUNCATE
    utilisateurs.cor_role_provider, -- DATA: (Sample data) NEED to insert new data.
    gn_monitoring.cor_individual_module, -- empty
    gn_monitoring.t_individuals, --empty
    gn_imports.t_imports_synthese, -- empty
    gn_imports.cor_role_mapping, -- empty
    gn_imports.cor_role_import, -- empty
    gn_permissions.backup_cor_role_action_filter_module_object, -- DATA: (Sample data) NEED to insert new data (?).
    gn_notifications.t_notifications_rules, -- DATA: (default) NEED to restore.
    gn_notifications.t_notifications,
    --gn_permissions.t_permissions_requests, -- TEST module: empty (TODO: remove this line)
    --pr_permission_request.t_permission_request, -- TEST module: empty (TODO: remove this line)
    gn_permissions.cor_permission_taxref, -- empty
    gn_permissions.cor_permission_area, -- empty
    gn_permissions.t_permissions, -- DATA: (Sample data) NEED to migrate.
    gn_monitoring.t_marking_events, -- empty
    gn_monitoring.cor_site_type, -- empty
    gn_monitoring.cor_site_area, -- empty
    gn_monitoring.cor_site_module, -- empty
    gn_monitoring.t_base_sites, -- empty
    gn_monitoring.t_observations, -- empty
    gn_monitoring.cor_visit_observer, --empty
    gn_monitoring.t_base_visits, -- emtpy
    gn_synthese.t_reports, -- empty
    gn_synthese.cor_observer_synthese, --empty
    gn_synthese.cor_area_synthese, --empty
    gn_synthese.synthese, --empty
    gn_commons.cor_module_dataset, -- empty
    gn_meta.cor_dataset_protocol, -- empty
    gn_meta.cor_dataset_territory, -- empty
    gn_meta.cor_dataset_actor, -- empty
    gn_commons.cor_field_dataset, -- empty
    gn_meta.t_datasets, -- empty
    gn_meta.t_bibliographical_references, -- empty
    gn_meta.cor_acquisition_framework_publication, -- empty
    gn_meta.cor_acquisition_framework_territory, -- empty
    gn_meta.cor_acquisition_framework_actor, -- empty
    gn_meta.cor_acquisition_framework_objectif, -- empty
    gn_meta.cor_acquisition_framework_voletsinp, -- empty
    gn_meta.t_acquisition_frameworks, -- empty
    gn_commons.t_places, -- empty
    gn_commons.t_validations, -- empty
    utilisateurs.cor_role_token, -- empty
    utilisateurs.cor_role_liste, -- empty
    utilisateurs.cor_role_app_profil, -- DATA: (Sample data) NEED to migrate.
    utilisateurs.cor_roles, -- DATA: (Sample data) NEED to migrate.
    utilisateurs.t_roles, -- DATA: (Sample data) NEED to migrate.
    gn_synthese.defaults_nomenclatures_value, -- DATA: (default) NEED to restore.
    gn_commons.t_parameters, -- DATA: (default) NEED to restore.
    ref_nomenclatures.defaults_nomenclatures_value, -- DATA: (default) NEED to restore.
    utilisateurs.temp_users, -- empty
    utilisateurs.bib_organismes -- DATA: (Sample data) NEED to migrate.
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
