-- Suppression de toutes les données de Flavia associées à la source ""
-- Si la table `gn2pg_flavia.data_json` existe, les triggers sont déclenchés.
-- Usage: psql -h "localhost" -U "<db-owner-name>" -d "<db-name>" -f <path-to-this-sql-file>
-- Ex.: psql -h "localhost" -U "geonatadmin" -d "geonature2db" -f ~/data/flavia/data/sql/update/001_*

BEGIN ;

\echo '-------------------------------------------------------------------------------'
\echo 'OBSERVATIONS SYNTHESE'

\echo 'Deletion in cor_area_synthese'
DELETE FROM gn_synthese.cor_area_synthese AS cas
USING gn_synthese.synthese AS sy,
    gn_synthese.t_sources AS so
WHERE cas.id_synthese = sy.id_synthese
    AND sy.id_source = so.id_source
    AND so.name_source = 'flavia' ;

\echo 'Deletion in synthese'
DELETE FROM gn_synthese.synthese AS sy
USING gn_synthese.t_sources AS so
WHERE sy.id_source = so.id_source
    AND so.name_source = 'flavia' ;

\echo '-------------------------------------------------------------------------------'
\echo 'DATASETS'

\echo 'Deletion in cor_dataset_actor'
DELETE FROM gn_meta.cor_dataset_actor AS act
USING gn_meta.t_datasets AS da,
    gn_synthese.synthese AS sy
WHERE act.id_dataset = da.id_dataset
    AND sy.id_dataset = da.id_dataset
    AND sy.id_synthese IS NULL ;

\echo 'Deletion in cor_dataset_territory'
DELETE FROM gn_meta.cor_dataset_territory AS te
USING gn_meta.t_datasets AS da,
    gn_synthese.synthese AS sy
WHERE te.id_dataset = da.id_dataset
    AND sy.id_dataset = da.id_dataset
    AND sy.id_synthese IS NULL ;

\echo 'Deletion in cor_dataset_protocol'
DELETE FROM gn_meta.cor_dataset_protocol AS pro
USING gn_meta.t_datasets AS da,
    gn_synthese.synthese AS sy
WHERE pro.id_dataset = da.id_dataset
    AND sy.id_dataset = da.id_dataset
    AND sy.id_synthese IS NULL ;

\echo 'Deletion in t_datasets'
DELETE FROM gn_meta.t_datasets AS da
USING gn_synthese.synthese AS sy
WHERE sy.id_dataset = da.id_dataset
    AND sy.id_synthese IS NULL ;

\echo '-------------------------------------------------------------------------------'
\echo 'ACQUISITION FRAMEWORKS'

\echo 'Deletion in cor_acquisition_framework_actor'
DELETE FROM gn_meta.cor_acquisition_framework_actor AS act
USING gn_meta.t_acquisition_frameworks AS af,
    gn_meta.t_datasets AS da
WHERE act.id_acquisition_framework = af.id_acquisition_framework
    AND af.id_acquisition_framework NOT IN (
        SELECT DISTINCT acquisition_framework_parent_id FROM  gn_meta.t_acquisition_frameworks
    )
    AND da.id_acquisition_framework = af.id_acquisition_framework
    AND da.id_dataset IS NULL ;

\echo 'Deletion in cor_acquisition_framework_objectif'
DELETE FROM gn_meta.cor_acquisition_framework_objectif AS obj
USING gn_meta.t_acquisition_frameworks AS af,
    gn_meta.t_datasets AS da
WHERE obj.id_acquisition_framework = af.id_acquisition_framework
    AND af.id_acquisition_framework NOT IN (
        SELECT DISTINCT acquisition_framework_parent_id FROM  gn_meta.t_acquisition_frameworks
    )
    AND da.id_acquisition_framework = af.id_acquisition_framework
    AND da.id_dataset IS NULL ;

\echo 'Deletion in cor_acquisition_framework_publication'
DELETE FROM gn_meta.cor_acquisition_framework_publication AS pub
USING gn_meta.t_acquisition_frameworks AS af,
    gn_meta.t_datasets AS da
WHERE pub.id_acquisition_framework = af.id_acquisition_framework
    AND af.id_acquisition_framework NOT IN (
        SELECT DISTINCT acquisition_framework_parent_id FROM  gn_meta.t_acquisition_frameworks
    )
    AND da.id_acquisition_framework = af.id_acquisition_framework
    AND da.id_dataset IS NULL ;

\echo 'Deletion in cor_acquisition_framework_voletsinp'
DELETE FROM gn_meta.cor_acquisition_framework_voletsinp AS vol
USING gn_meta.t_acquisition_frameworks AS af,
    gn_meta.t_datasets AS da
WHERE vol.id_acquisition_framework = af.id_acquisition_framework
    AND af.id_acquisition_framework NOT IN (
        SELECT DISTINCT acquisition_framework_parent_id FROM  gn_meta.t_acquisition_frameworks
    )
    AND da.id_acquisition_framework = af.id_acquisition_framework
    AND da.id_dataset IS NULL ;

\echo 'Deletion in t_acquisition_frameworks'
DELETE FROM gn_meta.t_acquisition_frameworks AS af
USING gn_meta.t_datasets AS da
WHERE af.id_acquisition_framework NOT IN (
        SELECT DISTINCT acquisition_framework_parent_id FROM  gn_meta.t_acquisition_frameworks
    )
    AND da.id_acquisition_framework = af.id_acquisition_framework
    AND da.id_dataset IS NULL ;


\echo '-------------------------------------------------------------------------------'
\echo 'ACQUISITION FRAMEWORKS - PARENTS'

\echo 'Deletion in cor_acquisition_framework_actor for parents AF'
DELETE FROM gn_meta.cor_acquisition_framework_actor AS act
USING gn_meta.t_acquisition_frameworks AS af,
    gn_meta.t_datasets AS da
WHERE act.id_acquisition_framework = af.id_acquisition_framework
    AND af.id_acquisition_framework NOT IN (
        SELECT DISTINCT acquisition_framework_parent_id FROM  gn_meta.t_acquisition_frameworks
    )
    AND af.is_parent = TRUE
    AND da.id_acquisition_framework = af.id_acquisition_framework
    AND da.id_dataset IS NULL ;

\echo 'Deletion in cor_acquisition_framework_objectif for parents AF'
DELETE FROM gn_meta.cor_acquisition_framework_objectif AS obj
USING gn_meta.t_acquisition_frameworks AS af,
    gn_meta.t_datasets AS da
WHERE obj.id_acquisition_framework = af.id_acquisition_framework
    AND af.id_acquisition_framework NOT IN (
        SELECT DISTINCT acquisition_framework_parent_id FROM  gn_meta.t_acquisition_frameworks
    )
    AND af.is_parent = TRUE
    AND da.id_acquisition_framework = af.id_acquisition_framework
    AND da.id_dataset IS NULL ;

\echo 'Deletion in cor_acquisition_framework_publication for parents AF'
DELETE FROM gn_meta.cor_acquisition_framework_publication AS pub
USING gn_meta.t_acquisition_frameworks AS af,
    gn_meta.t_datasets AS da
WHERE pub.id_acquisition_framework = af.id_acquisition_framework
    AND af.id_acquisition_framework NOT IN (
        SELECT DISTINCT acquisition_framework_parent_id FROM  gn_meta.t_acquisition_frameworks
    )
    AND af.is_parent = TRUE
    AND da.id_acquisition_framework = af.id_acquisition_framework
    AND da.id_dataset IS NULL ;

\echo 'Deletion in cor_acquisition_framework_voletsinp for parents AF'
DELETE FROM gn_meta.cor_acquisition_framework_voletsinp AS vol
USING gn_meta.t_acquisition_frameworks AS af,
    gn_meta.t_datasets AS da
WHERE vol.id_acquisition_framework = af.id_acquisition_framework
    AND af.id_acquisition_framework NOT IN (
        SELECT DISTINCT acquisition_framework_parent_id FROM  gn_meta.t_acquisition_frameworks
    )
    AND af.is_parent = TRUE
    AND da.id_acquisition_framework = af.id_acquisition_framework
    AND da.id_dataset IS NULL ;

\echo 'Deletion in t_acquisition_frameworks for parents AF'
DELETE FROM gn_meta.t_acquisition_frameworks AS af
USING gn_meta.t_datasets AS da
WHERE af.id_acquisition_framework NOT IN (
        SELECT DISTINCT acquisition_framework_parent_id FROM  gn_meta.t_acquisition_frameworks
    )
    AND af.is_parent = TRUE
    AND da.id_acquisition_framework = af.id_acquisition_framework
    AND da.id_dataset IS NULL ;

\echo '-------------------------------------------------------------------------------'
\echo 'USERS & ORGANISMS'

DELETE FROM utilisateurs.cor_roles AS cr
USING utilisateurs.t_roles AS r
WHERE cr.id_role_utilisateur = r.id_role
    AND r.champs_addi ->> 'source' = 'flavia'
    AND r.champs_addi ->> 'module' = 'gn2pg' ;

\echo 'Deletion in t_roles'
DELETE FROM utilisateurs.t_roles
WHERE champs_addi ->> 'source' = 'flavia'
    AND champs_addi ->> 'module' = 'gn2pg'
    AND id_role NOT IN (
        SELECT DISTINCT id_role_utilisateur
        FROM utilisateurs.cor_roles
    )
    AND id_role NOT IN (
        SELECT DISTINCT id_role
        FROM utilisateurs.cor_role_liste
    )
    AND id_role NOT IN (
        SELECT DISTINCT id_validator
        FROM gn_commons.t_validations
    )
    AND id_role NOT IN (
        SELECT DISTINCT id_role
        FROM gn_commons.t_places
    )
    AND id_role NOT IN (
        SELECT DISTINCT id_digitizer
        FROM gn_meta.t_acquisition_frameworks
    )
    AND id_role NOT IN (
        SELECT DISTINCT id_role
        FROM gn_meta.cor_acquisition_framework_actor
    )
    AND id_role NOT IN (
        SELECT DISTINCT id_digitizer
        FROM gn_meta.t_datasets
    )
    AND id_role NOT IN (
        SELECT DISTINCT id_role
        FROM gn_meta.cor_dataset_actor
    )
    AND id_role NOT IN (
        SELECT DISTINCT id_role
        FROM gn_permissions.cor_role_action_filter_module_object
    )
    AND id_role NOT IN (
        SELECT DISTINCT id_digitiser
        FROM gn_synthese.synthese
    )
    AND id_role NOT IN (
        SELECT DISTINCT id_role
        FROM gn_synthese.cor_observer_synthese
    )
    AND id_role NOT IN (
        SELECT DISTINCT id_inventor
        FROM gn_monitoring.t_base_sites
    )
    AND id_role NOT IN (
        SELECT DISTINCT id_digitiser
        FROM gn_monitoring.t_base_sites
    )
    AND id_role NOT IN (
        SELECT DISTINCT id_digitiser
        FROM gn_monitoring.t_base_visits
    )
    AND id_role NOT IN (
        SELECT DISTINCT id_role
        FROM gn_monitoring.cor_visit_observer
    )
;

\echo 'Deletion in bib_organismes'
DELETE FROM utilisateurs.bib_organismes
WHERE id_organisme NOT IN (
        SELECT DISTINCT id_organisme
        FROM utilisateurs.t_roles
    )
    AND id_organisme NOT IN (
        SELECT DISTINCT id_organism
        FROM gn_meta.cor_dataset_actor
    )
    AND id_organisme NOT IN (
        SELECT DISTINCT id_organism
        FROM gn_meta.cor_acquisition_framework_actor
    )
    AND id_organisme NOT IN (
        SELECT DISTINCT id_parent
        FROM utilisateurs.bib_organismes
    )
    AND id_organisme NOT IN (
        SELECT DISTINCT id_organism
        FROM gn_commons.t_parameters
    )
    AND id_organisme NOT IN (
        SELECT DISTINCT id_organism
        FROM ref_nomenclatures.defaults_nomenclatures_value
    )
    AND id_organisme NOT IN (
        SELECT DISTINCT id_organism
        FROM gn_synthese.defaults_nomenclatures_value
    )
    AND id_organisme NOT IN (
        SELECT DISTINCT id_organisme
        FROM utilisateurs.temp_users
    );

\echo '-------------------------------------------------------------------------------'
\echo 'GN2PG'

\echo 'Clean data_json'
TRUNCATE gn2pg_flavia.data_json ;

\echo 'Clean download_log'
TRUNCATE gn2pg_flavia.download_log ;

\echo 'Clean error_log'
TRUNCATE gn2pg_flavia.error_log ;

\echo 'Clean increment_log'
TRUNCATE gn2pg_flavia.increment_log ;

\echo 'Remove tmp_fix_obs_to_delete'
DROP TABLE IF EXISTS gn2pg_flavia.tmp_fix_obs_to_delete ;

COMMIT;
