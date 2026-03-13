-- Script to migrate only permissions requests accepted and not finished
-- TODO: check if we need to create a table (cor_request_permission) between t_permission_request and
-- the table t_permission.

BEGIN;

\echo '----------------------------------------------------------------------------'
\echo 'Add new column to pr_permission_request.t_permission_request'

ALTER TABLE pr_permission_request.t_permission_request
ADD COLUMN IF NOT EXISTS additional_data JSONB ;


\echo '----------------------------------------------------------------------------'
\echo 'Add temporary column to gn_permissions.t_permissions'

ALTER TABLE gn_permissions.t_permissions
ADD COLUMN IF NOT EXISTS migration_request_uuid UUID ;


\echo '----------------------------------------------------------------------------'
\echo 'Migrate accepted and not finished permission requests'

WITH new_permissions AS (
    INSERT INTO gn_permissions.t_permissions (
        id_role,
        id_action,
        id_module,
        id_object,
        scope_value,
        sensitivity_filter,
        created_on,
        expire_on,
        validated,
        migration_request_uuid
    )
    SELECT
        utilisateurs.get_id_role_by_uuid(r.requested_by) AS id_role,
        gn_permissions.get_id_action_by_code(actions.code) AS id_action,
        gn_commons.get_id_module_by_code('SYNTHESE') AS id_module,
        gn_permissions.get_id_object_by_code('ALL') AS id_object,
        NULL AS scope_value,
        TRUE AS sensitivity_filter,
        r.meta_create_date AS created_on,
        r.end_date AS expire_on,
        TRUE AS validated,
        r.token
    FROM pr_permission_request.tmp_permission_request AS r
        CROSS JOIN (VALUES ('R'), ('E')) AS actions(code)
    WHERE NOT EXISTS (
        SELECT 'TRUE'
        FROM gn_permissions.t_permissions p
        WHERE p.id_role = utilisateurs.get_id_role_by_uuid(r.requested_by)
          AND p.id_action = gn_permissions.get_id_action_by_code(actions.code)
          AND p.id_module = gn_commons.get_id_module_by_code('SYNTHESE')
          AND p.id_object = gn_permissions.get_id_object_by_code('ALL')
          AND p.scope_value IS NULL
          AND p.expire_on = r.end_date
          AND p.created_on = r.meta_create_date
    )
    RETURNING *
),
inserted_requests AS (
    INSERT INTO pr_permission_request.t_permission_request (
        id_permission,
        id_author,
        id_validator,
        validation_date,
        additional_data
    )
    SELECT
        np.id_permission,
        np.id_role,
        utilisateurs.get_id_role_by_uuid(r.processed_by),
        r.processed_date,
        r.additional_data
    FROM new_permissions AS np
        JOIN pr_permission_request.tmp_permission_request AS r
            ON r.token = np.migration_request_uuid
    RETURNING id_permission
),
inserted_taxa_filters AS (
    INSERT INTO gn_permissions.cor_permission_taxref (
        id_permission,
        cd_nom
    )
    SELECT
        np.id_permission,
        trim(unnest(string_to_array(r.taxonomic_filter, ',')))::integer
    FROM new_permissions AS np
        JOIN pr_permission_request.tmp_permission_request AS r
            ON r.token = np.migration_request_uuid
    WHERE r.taxonomic_filter IS NOT NULL
        AND r.taxonomic_filter != ''
    RETURNING id_permission
),
inserted_area_filters AS (
    INSERT INTO gn_permissions.cor_permission_area (
        id_permission,
        id_area
    )
    SELECT
        np.id_permission,
        trim(unnest(string_to_array(r.geographic_filter, ',')))::integer
    FROM new_permissions AS np
        JOIN pr_permission_request.tmp_permission_request AS r
            ON r.token = np.migration_request_uuid
    WHERE r.geographic_filter IS NOT NULL
        AND r.geographic_filter != ''
    RETURNING id_permission
)
SELECT
    (SELECT count(*) FROM new_permissions) AS new_permissions_count,
    (SELECT count(*) FROM inserted_requests) AS inserted_requests_count,
    (SELECT count(*) FROM inserted_taxa_filters) AS inserted_taxa_filters_count,
    (SELECT count(*) FROM inserted_area_filters) AS inserted_area_filters_count;


\echo '----------------------------------------------------------------------------'
\echo 'Remove temporary column to gn_permissions.t_permissions'

ALTER TABLE gn_permissions.t_permissions
DROP COLUMN IF EXISTS migration_request_uuid;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is OK:'
--COMMIT;
COMMIT;
