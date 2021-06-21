-- Required rights: DB OWNER
-- GeoNature database compatibility : v2.6.0+
-- Fix integrated users by scripts.
BEGIN;

\echo '-------------------------------------------------------------------------------'
\echo 'Add function to get group id by name'
CREATE OR REPLACE FUNCTION utilisateurs.get_id_group_by_name(groupName character varying)
    RETURNS integer
    LANGUAGE plpgsql
    IMMUTABLE
AS $function$
    -- Function which return the id_role of a group by its name
    DECLARE idRole integer;

    BEGIN
        SELECT INTO idRole tr.id_role
        FROM utilisateurs.t_roles AS tr
        WHERE tr.nom_role = groupName
            AND tr.groupe = true ;

        RETURN idRole ;
    END;
$function$ ;


\echo '-------------------------------------------------------------------------------'
\echo 'Set active to true in "t_roles" for users with identifier and email.'
UPDATE utilisateurs.t_roles
SET active = true
WHERE (email IS NOT NULL AND email != '')
    AND (identifiant IS NOT NULL AND identifiant != '')
    AND active IS NULL ;


\echo '-------------------------------------------------------------------------------'
\echo 'Set active to false in "t_roles" for users with no identifier or no email.'
UPDATE utilisateurs.t_roles
SET active = false
WHERE (
        (email IS NULL OR email = '')
        OR (identifiant IS NULL OR identifiant = '')
    )
    AND groupe = false ;


\echo '-------------------------------------------------------------------------------'
\echo 'Add users with identifier and email to "Grp_utilisateurs" group.'
INSERT INTO utilisateurs.cor_roles (id_role_groupe, id_role_utilisateur)
    SELECT
        utilisateurs.get_id_group_by_name('Grp_utilisateurs'),
        tr.id_role
    FROM utilisateurs.t_roles AS tr
    WHERE (tr.email IS NOT NULL AND tr.email != '')
        AND (tr.identifiant IS NOT NULL AND tr.identifiant != '')
        AND tr.active = true
        AND NOT EXISTS (
            SELECT 'X'
            FROM utilisateurs.cor_roles AS cr
            WHERE cr.id_role_groupe = utilisateurs.get_id_group_by_name('Grp_utilisateurs')
                AND cr.id_role_utilisateur = tr.id_role
        ) ;


\echo '-------------------------------------------------------------------------------'
\echo 'Remove inactive users from "Grp_utilisateurs" group.'
DELETE FROM utilisateurs.cor_roles
WHERE id_role_groupe = utilisateurs.get_id_group_by_name('Grp_utilisateurs')
    AND id_role_utilisateur IN (
        SELECT id_role
        FROM utilisateurs.t_roles
        WHERE active = false
    ) ;


\echo '-------------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
