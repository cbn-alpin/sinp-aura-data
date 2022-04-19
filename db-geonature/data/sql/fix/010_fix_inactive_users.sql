-- Fix inactive users with email.
-- Required rights: DB OWNER
-- GeoNature database compatibility : v2.6.0+

BEGIN;


\echo '-------------------------------------------------------------------------------'
\echo 'Set new "identifier" if already exists.'
UPDATE utilisateurs.t_roles AS tr SET
    identifiant = concat(split_part(tr.email, '@', 1), '-', length(split_part(tr.email, '@', 1))),
    active = TRUE
WHERE tr.groupe = FALSE
    AND tr.active = FALSE
    AND (tr.identifiant IS NULL OR tr.identifiant = '')
	AND tr.email IS NOT NULL
	AND tr.email != ''
	AND tr.email ILIKE '%@%'
	AND EXISTS (
		SELECT 'x'
		FROM utilisateurs.t_roles AS tr1
		WHERE tr1.identifiant = split_part(tr.email, '@', 1)
	);


\echo '-------------------------------------------------------------------------------'
\echo 'Set new "identifier" if duplicate by update.'
UPDATE utilisateurs.t_roles AS tr SET
    identifiant = concat(split_part(tr.email, '@', 1), '-', floor(random() * 100 + 1)::varchar),
    active = TRUE
WHERE tr.groupe = FALSE
    AND tr.active = FALSE
    AND (tr.identifiant IS NULL OR tr.identifiant = '')
	AND tr.email IS NOT NULL
	AND tr.email != ''
	AND tr.email ILIKE '%@%'
	AND split_part(tr.email, '@', 1) IN (
		SELECT split_part(tr1.email, '@', 1) AS identifiant
		FROM utilisateurs.t_roles AS tr1
		WHERE tr1.groupe = FALSE
		    AND tr1.active = FALSE
		    AND (tr1.identifiant IS NULL OR tr1.identifiant = '')
			AND tr1.email IS NOT NULL
			AND tr1.email != ''
			AND tr1.email ILIKE '%@%'
		GROUP BY split_part(tr1.email, '@', 1)
		HAVING COUNT(*) > 1
);


\echo '-------------------------------------------------------------------------------'
\echo 'Set "identifier" if NOT exists.'
UPDATE utilisateurs.t_roles AS tr SET
    identifiant = split_part(tr.email, '@', 1),
    active = TRUE
WHERE tr.groupe = FALSE
    AND tr.active = FALSE
    AND (tr.identifiant IS NULL OR tr.identifiant = '')
	AND tr.email IS NOT NULL
	AND tr.email != ''
	AND tr.email ILIKE '%@%'
	AND NOT EXISTS (
		SELECT 'x'
		FROM utilisateurs.t_roles AS tr1
		WHERE tr1.identifiant = split_part(tr.email, '@', 1)
	);


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
\echo 'COMMIT if all is ok:'
COMMIT;
