-- Migrate to GeoNature v2.16/2.17
-- Add global permissions

BEGIN;

\echo '----------------------------------------------------------------------------'
\echo 'Add all permissions to "Adinistrateurs" group'

INSERT INTO gn_permissions.t_permissions (id_role, id_module, id_object, id_action)
    SELECT
        utilisateurs.get_id_group_by_name('Grp_admin'),
        id_module,
        id_object,
        id_action
    FROM gn_permissions.t_permissions_available ;


\echo '----------------------------------------------------------------------------'
\echo 'Add permissions to all groups for module PERMISSION_REQUEST'

INSERT INTO gn_permissions.t_permissions (
    id_role,
    id_action,
    id_module,
    id_object,
    scope_value
) VALUES (
    utilisateurs.get_id_group_by_name('Grp_utilisateurs'),
    gn_permissions.get_id_action_by_code('C'), -- Lire (C)
    gn_commons.get_id_module_bycode('PERMISSION_REQUEST'),
    gn_permissions.get_id_object('ALL'),
    gn_permissions.get_id_scope_by_label('Mes données')
), (
    utilisateurs.get_id_group_by_name('Grp_utilisateurs'),
    gn_permissions.get_id_action_by_code('R'), -- Lire (R)
    gn_commons.get_id_module_bycode('PERMISSION_REQUEST'),
    gn_permissions.get_id_object('ALL'),
    gn_permissions.get_id_scope_by_label('Mes données')
), (
    utilisateurs.get_id_group_by_name('Grp_utilisateurs'),
    gn_permissions.get_id_action_by_code('U'), -- Mettre à jour (U)
    gn_commons.get_id_module_bycode('PERMISSION_REQUEST'),
    gn_permissions.get_id_object('ALL'),
    gn_permissions.get_id_scope_by_label('Mes données')
), (
    utilisateurs.get_id_group_by_name('Grp_utilisateurs'),
    gn_permissions.get_id_action_by_code('D'), -- Supprimer (D)
    gn_commons.get_id_module_bycode('PERMISSION_REQUEST'),
    gn_permissions.get_id_object('ALL'),
    gn_permissions.get_id_scope_by_label('Mes données')
) ;


\echo '----------------------------------------------------------------------------'
\echo 'Add permissions to all groups for module PERMISSIONS_REQUESTS (TEMPORARY)'

INSERT INTO gn_permissions.t_permissions (
    id_role,
    id_action,
    id_module,
    id_object,
    scope_value
) VALUES (
    utilisateurs.get_id_group_by_name('Grp_utilisateurs'),
    gn_permissions.get_id_action_by_code('C'), -- Lire (C)
    gn_commons.get_id_module_bycode('PERMISSIONS_REQUESTS'),
    gn_permissions.get_id_object('ALL'),
    gn_permissions.get_id_scope_by_label('Mes données')
), (
    utilisateurs.get_id_group_by_name('Grp_utilisateurs'),
    gn_permissions.get_id_action_by_code('R'), -- Lire (R)
    gn_commons.get_id_module_bycode('PERMISSIONS_REQUESTS'),
    gn_permissions.get_id_object('ALL'),
    gn_permissions.get_id_scope_by_label('Mes données')
), (
    utilisateurs.get_id_group_by_name('Grp_utilisateurs'),
    gn_permissions.get_id_action_by_code('U'), -- Mettre à jour (U)
    gn_commons.get_id_module_bycode('PERMISSIONS_REQUESTS'),
    gn_permissions.get_id_object('ALL'),
    gn_permissions.get_id_scope_by_label('Mes données')
), (
    utilisateurs.get_id_group_by_name('Grp_utilisateurs'),
    gn_permissions.get_id_action_by_code('D'), -- Supprimer (D)
    gn_commons.get_id_module_bycode('PERMISSIONS_REQUESTS'),
    gn_permissions.get_id_object('ALL'),
    gn_permissions.get_id_scope_by_label('Mes données')
) ;


\echo '----------------------------------------------------------------------------'
\echo 'Add permissions to "Utilisateurs" group for module EXPORT'

INSERT INTO gn_permissions.t_permissions (
    id_role,
    id_action,
    id_module,
    id_object,
    scope_value
) VALUES (
    utilisateurs.get_id_group_by_name('Grp_utilisateurs'),
    gn_permissions.get_id_action_by_code('R'), -- Lire (R)
    gn_commons.get_id_module_bycode('EXPORTS'),
    gn_permissions.get_id_object('ALL'),
    gn_permissions.get_id_scope_by_label('Mes données')
) ;


\echo '----------------------------------------------------------------------------'
\echo 'Add permissions to "Utilisateurs" group for module SYNTHESE'

INSERT INTO gn_permissions.t_permissions (
    id_role,
    id_action,
    id_module,
    id_object,
    scope_value
) VALUES (
    utilisateurs.get_id_group_by_name('Grp_utilisateurs'),
    gn_permissions.get_id_action_by_code('R'), -- Lire (R)
    gn_commons.get_id_module_bycode('SYNTHESE'),
    gn_permissions.get_id_object('ALL'),
    NULL -- De tout le monde
), (
    utilisateurs.get_id_group_by_name('Grp_utilisateurs'),
    gn_permissions.get_id_action_by_code('E'), -- Exporter (E)
    gn_commons.get_id_module_bycode('SYNTHESE'),
    gn_permissions.get_id_object('ALL'),
    NULL -- De tout le monde
) ;


\echo '----------------------------------------------------------------------------'
\echo 'Add permissions to "Police Région" group for module SYNTHESE'

INSERT INTO gn_permissions.t_permissions (
    id_role,
    id_action,
    id_module,
    id_object,
    scope_value,
    sensitivity_filter
) VALUES (
    utilisateurs.get_id_group_by_name('Grp_police_region'),
    gn_permissions.get_id_action_by_code('R'), -- Lire (R)
    gn_commons.get_id_module_bycode('SYNTHESE'),
    gn_permissions.get_id_object('ALL'),
    NULL, -- De tout le monde,
    TRUE
), (
    utilisateurs.get_id_group_by_name('Grp_police_region'),
    gn_permissions.get_id_action_by_code('E'), -- Exporter (E)
    gn_commons.get_id_module_bycode('SYNTHESE'),
    gn_permissions.get_id_object('ALL'),
    NULL, -- De tout le monde
    TRUE
) ;


\echo '----------------------------------------------------------------------------'
\echo 'Add permissions to "Rédacteurs" group for module TAXHUB'

INSERT INTO gn_permissions.t_permissions (
    id_role,
    id_action,
    id_module,
    id_object
) VALUES (
    utilisateurs.get_id_group_by_name('Grp_redacteurs'),
    gn_permissions.get_id_action_by_code('R'), -- Lire (R)
    gn_commons.get_id_module_bycode('TAXHUB'),
    gn_permissions.get_id_object('ATTRIBUTS')
), (
    utilisateurs.get_id_group_by_name('Grp_redacteurs'),
    gn_permissions.get_id_action_by_code('R'), -- Lire (R)
    gn_commons.get_id_module_bycode('TAXHUB'),
    gn_permissions.get_id_object('LISTES')
), (
    utilisateurs.get_id_group_by_name('Grp_redacteurs'),
    gn_permissions.get_id_action_by_code('R'), -- Lire (R)
    gn_commons.get_id_module_bycode('TAXHUB'),
    gn_permissions.get_id_object('THEMES')
), (
    utilisateurs.get_id_group_by_name('Grp_redacteurs'),
    gn_permissions.get_id_action_by_code('R'), -- Lire (R)
    gn_commons.get_id_module_bycode('TAXHUB'),
    gn_permissions.get_id_object('TAXONS')
), (
    utilisateurs.get_id_group_by_name('Grp_redacteurs'),
    gn_permissions.get_id_action_by_code('U'), -- Mettre à jour (U)
    gn_commons.get_id_module_bycode('TAXHUB'),
    gn_permissions.get_id_object('TAXONS')
) ;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is OK:'
COMMIT ;
