-- Required rights: DB OWNER
-- GeoNature database compatibility : v2.6.0+
-- Delete properly duplicate users.
-- Use this scirpt this way: psql -h localhost -U geonatadmin -d geonature2db \
--      -v 'oldIdRole=<old_id_role>' -v 'newIdRole=<new_id_role>' \
--      -f ~/data/db-geonature/data/sql/13_delete_duplicate_user.sql
-- Tables qui ne seront pas traitées :
--      utilisateurs.cor_roles_app_profil => ne semble gérer que des groupes !
--      utilisateurs.cor_role_token => uniquement pour les utilisateurs temporaire (création de compte)

-- Tables qui ne sont pas utilisé dans le SINP AURA :
--      gn_monitoring.t_base_sites (id_inventor, id_digitiser)
--      gn_monitoring.t_base_visits
--      gn_monitoring.cor_visit_observer
--      pr_occtax.t_releves_occtax
--      pr_occtax.cor_role_releves_occtax
--      pr_occhab.t_stations
--      pr_occhab.cor_station_observer
--
-- List of old id_role / new id_role:
-- old local : IN (167, 152, 192, 36, 196, 148, 25, 137, 81, 124, 165, 39, 126, 96, 60, 12, 208, 71, 75)
-- old prod : IN (169, 154, 194, 38, 198, 150, 27, 139, 83, 126, 167, 41, 128, 98, 62, 14, 210, 73, 77)
--
-- 169  80
-- 154  113
-- 194  193
-- 38   39
-- 198  85
-- 150  56
-- 27   191
-- 139  15
-- 83   12
-- 126  53
-- 167  48
-- 41   24
-- 128  134
-- 98   97
-- 62   97
-- 14   65
-- 210  99
-- 73   99
-- 77   99

BEGIN;

-- Tables à mettre à jour :

\echo '-------------------------------------------------------------------------------'
\echo 'Replace old id_role in "utilisateurs.cor_roles"'
UPDATE utilisateurs.cor_roles AS cr SET
    id_role_utilisateur = :newIdRole
WHERE cr.id_role_utilisateur = :oldIdRole
    AND NOT EXISTS (
		SELECT 'x'
		FROM utilisateurs.cor_roles AS cr1
		WHERE cr1.id_role_utilisateur = :newIdRole
            AND cr1.id_role_groupe = cr.id_role_groupe
	) ;

\echo 'Delete old id_role in "utilisateurs.cor_roles" when new id_role already exists'
DELETE FROM utilisateurs.cor_roles
WHERE id_role_utilisateur = :oldIdRole ;


\echo '-------------------------------------------------------------------------------'
\echo 'Replace old id_role in "utilisateurs.cor_role_liste"'
UPDATE utilisateurs.cor_role_liste AS crl SET
    id_role = :newIdRole
WHERE crl.id_role = :oldIdRole
    AND NOT EXISTS (
		SELECT 'x'
		FROM utilisateurs.cor_role_liste AS crl1
		WHERE crl1.id_role = :newIdRole
            AND crl1.id_liste = crl.id_liste
	) ;

\echo 'Delete old id_role in "utilisateurs.cor_role_liste" when new id_role already exists'
DELETE FROM utilisateurs.cor_role_liste
WHERE id_role = :oldIdRole ;


\echo '-------------------------------------------------------------------------------'
\echo 'Replace old id_role in "gn_commons.t_validations"'
UPDATE gn_commons.t_validations AS tv SET
    id_validator = :newIdRole
WHERE tv.id_validator = :oldIdRole
    AND NOT EXISTS (
		SELECT 'x'
		FROM gn_commons.t_validations AS tv1
		WHERE tv1.id_validator = :newIdRole
            AND tv1.uuid_attached_row = tv.uuid_attached_row
            AND tv1.id_nomenclature_valid_status = tv.id_nomenclature_valid_status
            AND tv1.validation_auto = tv.validation_auto
            AND tv1.validation_comment = tv.validation_comment
            AND tv1.validation_date = tv.validation_date
	) ;

\echo 'Delete old id_role in "gn_commons.t_validations" when new id_role already exists'
DELETE FROM gn_commons.t_validations
WHERE id_validator = :oldIdRole ;


\echo '-------------------------------------------------------------------------------'
\echo 'Replace old id_role in "gn_commons.t_places"'
UPDATE gn_commons.t_places AS tp SET
    id_role = :newIdRole
WHERE tp.id_role = :oldIdRole
    AND NOT EXISTS (
		SELECT 'x'
		FROM gn_commons.t_places AS tp1
		WHERE tp1.id_role = :newIdRole
            AND tp1.place_name = tp.place_name
            AND tp1.place_geom = tp.place_geom
	) ;

\echo 'Delete old id_role in "gn_commons.t_places" when new id_role already exists'
DELETE FROM gn_commons.t_places
WHERE id_role = :oldIdRole ;


\echo '-------------------------------------------------------------------------------'
\echo 'Replace old id_role in "gn_meta.t_acquisition_frameworks"'
UPDATE gn_meta.t_acquisition_frameworks AS taf SET
    id_digitizer = :newIdRole
WHERE taf.id_digitizer = :oldIdRole ;


\echo '-------------------------------------------------------------------------------'
\echo 'Replace old id_role in "gn_meta.cor_acquisition_framework_actor"'
UPDATE gn_meta.cor_acquisition_framework_actor AS cafa SET
    id_role = :newIdRole
WHERE cafa.id_role = :oldIdRole
    AND NOT EXISTS (
		SELECT 'x'
		FROM gn_meta.cor_acquisition_framework_actor AS cafa1
		WHERE cafa1.id_role = :newIdRole
            AND cafa1.id_acquisition_framework = cafa.id_acquisition_framework
            AND cafa1.id_nomenclature_actor_role = cafa.id_nomenclature_actor_role
	) ;

\echo 'Delete old id_role in "gn_meta.cor_acquisition_framework_actor" when new id_role already exists'
DELETE FROM gn_meta.cor_acquisition_framework_actor
WHERE id_role = :oldIdRole ;


\echo '-------------------------------------------------------------------------------'
\echo 'Replace old id_role in "gn_meta.t_datasets"'
UPDATE gn_meta.t_datasets AS td SET
    id_digitizer = :newIdRole
WHERE td.id_digitizer = :oldIdRole ;


\echo '-------------------------------------------------------------------------------'
\echo 'Replace old id_role in "gn_meta.cor_dataset_actor"'
UPDATE gn_meta.cor_dataset_actor AS cda SET
    id_role = :newIdRole
WHERE cda.id_role = :oldIdRole
    AND NOT EXISTS (
		SELECT 'x'
		FROM gn_meta.cor_dataset_actor AS cda1
		WHERE cda1.id_role = :newIdRole
            AND cda1.id_dataset = cda.id_dataset
            AND cda1.id_nomenclature_actor_role = cda.id_nomenclature_actor_role
	) ;

\echo 'Delete old id_role in "gn_meta.cor_dataset_actor" when new id_role already exists'
DELETE FROM gn_meta.cor_dataset_actor
WHERE id_role = :oldIdRole ;

\echo '-------------------------------------------------------------------------------'
\echo 'Replace old id_role in "gn_permissions.cor_role_action_filter_module_object"'
UPDATE gn_permissions.cor_role_action_filter_module_object AS crafmo SET
    id_role = :newIdRole
WHERE crafmo.id_role = :oldIdRole
    AND NOT EXISTS (
		SELECT 'x'
		FROM gn_permissions.cor_role_action_filter_module_object AS crafmo1
		WHERE crafmo1.id_role = :newIdRole
            AND crafmo1.id_module = crafmo.id_module
            AND crafmo1.id_action = crafmo.id_action
            AND crafmo1.id_object = crafmo.id_object
            AND crafmo1.id_filter_type = crafmo.id_filter_type
            AND crafmo1.value_filter = crafmo.value_filter
	) ;

\echo 'Delete old id_role in "gn_permissions.cor_role_action_filter_module_object" when new id_role already exists'
DELETE FROM gn_permissions.cor_role_action_filter_module_object
WHERE id_role = :oldIdRole ;


\echo '-------------------------------------------------------------------------------'
\echo 'Replace old id_role in "gn_permissions.t_requests"'
UPDATE gn_permissions.t_requests AS tr SET
    id_role = :newIdRole
WHERE tr.id_role = :oldIdRole ;

\echo 'Replace old processed_by in "gn_permissions.t_requests"'
UPDATE gn_permissions.t_requests AS tr SET
    processed_by = :newIdRole
WHERE tr.processed_by = :oldIdRole ;


\echo '-------------------------------------------------------------------------------'
\echo 'Replace old id_digitiser in "gn_synthese.synthese"'
UPDATE gn_synthese.synthese AS s SET
    id_digitiser = :newIdRole
WHERE s.id_digitiser = :oldIdRole ;


\echo '-------------------------------------------------------------------------------'
\echo 'Replace old id_role in "gn_synthese.cor_observer_synthese"'
UPDATE gn_synthese.cor_observer_synthese AS cos0 SET
    id_role = :newIdRole
WHERE cos0.id_role = :oldIdRole
    AND NOT EXISTS (
		SELECT 'x'
		FROM gn_synthese.cor_observer_synthese AS cos1
		WHERE cos1.id_role = :newIdRole
            AND cos1.id_synthese = cos0.id_synthese
	) ;


\echo '-------------------------------------------------------------------------------'
\echo 'Delete old t_roles entry'
DELETE FROM utilisateurs.t_roles
WHERE id_role = :oldIdRole ;


\echo '-------------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
