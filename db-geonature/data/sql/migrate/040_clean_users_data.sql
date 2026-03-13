-- Migrate to GeoNature v2.16/2.17
-- Clean utilisateurs data after migrations

BEGIN;

\echo '----------------------------------------------------------------------------'
\echo 'Insert applications in utilisateurs.t_applications'

INSERT INTO utilisateurs.t_applications (
    code_application,
    nom_application,
    desc_application,
    id_parent
) VALUES
    ('UH', 'UsersHub', 'Application permettant d''administrer la présente base de données.', NULL),
    ('TH', 'TaxHub', 'Application permettant d''administrer les taxons.', NULL) ;


\echo '----------------------------------------------------------------------------'
\echo 'Insert group-app-profil in utilisateurs.cor_role_app_profil'
INSERT INTO utilisateurs.cor_role_app_profil (
    id_role,
    id_application,
    id_profil,
    is_default_group_for_app
) VALUES (
    utilisateurs.get_id_group_by_name('Grp_admin'), -- id: 9
    utilisateurs.get_id_app_by_code('UH'), -- id: 1
    utilisateurs.get_id_profil_by_name('Administrateur'), -- id: 6
    false
), (
    utilisateurs.get_id_group_by_name('Grp_admin'), -- id: 9
    utilisateurs.get_id_app_by_code('TH'), -- id: 2
    utilisateurs.get_id_profil_by_name('Administrateur'), -- id: 6
    false
), (
    utilisateurs.get_id_group_by_name('Grp_admin'), -- id: 9
    utilisateurs.get_id_app_by_code('GN'), -- id: 3
    utilisateurs.get_id_profil_by_name('Lecteur'), -- id: 1
    false
), (
    utilisateurs.get_id_group_by_name('Grp_utilisateurs'), -- id: 7
    utilisateurs.get_id_app_by_code('GN'), -- id: 3
    utilisateurs.get_id_profil_by_name('Lecteur'), -- id: 1
    true
), (
    utilisateurs.get_id_group_by_name('Grp_police_region'), -- id: 333
    utilisateurs.get_id_app_by_code('GN'), -- id: 3
    utilisateurs.get_id_profil_by_name('Lecteur'), -- id: 1
    false
), (
    utilisateurs.get_id_group_by_name('Grp_redacteurs'), -- id: 714
    utilisateurs.get_id_app_by_code('TH'), -- id: 2
    utilisateurs.get_id_profil_by_name('Référent'), -- id: 3
    false
);


\echo '----------------------------------------------------------------------------'
\echo 'Insert profil-app in utilisateurs.cor_profil_for_app'

INSERT INTO utilisateurs.cor_profil_for_app (
    id_profil,
    id_application
) VALUES (
    utilisateurs.get_id_profil_by_name('Administrateur'), -- id: 6
    utilisateurs.get_id_app_by_code('UH') -- id: 1
), (
    utilisateurs.get_id_profil_by_name('Référent'), -- id: 3
    utilisateurs.get_id_app_by_code('UH') -- id: 1
), (
    utilisateurs.get_id_profil_by_name('Rédacteur'), -- id: 2
    utilisateurs.get_id_app_by_code('TH') -- id: 2
), (
    utilisateurs.get_id_profil_by_name('Référent'), -- id: 3
    utilisateurs.get_id_app_by_code('TH') -- id: 2
), (
    utilisateurs.get_id_profil_by_name('Modérateur'), -- id: 4
    utilisateurs.get_id_app_by_code('TH') -- id: 2
), (
    utilisateurs.get_id_profil_by_name('Administrateur'), -- id: 6
    utilisateurs.get_id_app_by_code('TH') -- id: 2
), (
    utilisateurs.get_id_profil_by_name('Lecteur'), -- id: 1
    utilisateurs.get_id_app_by_code('GN') -- id: 3
)
ON CONFLICT DO NOTHING ;


\echo '----------------------------------------------------------------------------'
\echo 'Re-insert link between roles and organisms'

WITH organism_mapping AS (
    SELECT
        (additional_data -> 'migrate2026' ->> 'idOrganismSrc')::integer AS old_id,
        id_organisme AS new_id
    FROM utilisateurs.bib_organismes
    WHERE additional_data ? 'migrate2026'
)
UPDATE utilisateurs.t_roles AS r
SET id_organisme = o.new_id
FROM organism_mapping AS o
WHERE (r.champs_addi -> 'migrate2026' ->> 'idOrganismSrc')::integer = o.old_id ;


\echo '----------------------------------------------------------------------------'
\echo 'Clean t_roles champs_addi JSON'

UPDATE utilisateurs.t_roles AS r
SET champs_addi = (r.champs_addi - 'validate_charte') || '{"validateCharte": true}'::jsonb
WHERE r.champs_addi -> 'validate_charte' = '["true"]'::jsonb;


\echo '----------------------------------------------------------------------------'
\echo 'Reorder id_organisme in bib_organisme'

UPDATE utilisateurs.bib_organismes
SET id_organisme = -id_organisme ;

UPDATE utilisateurs.bib_organismes
SET id_organisme = ABS(id_organisme) - 2 ;


\echo '----------------------------------------------------------------------------'
\echo 'Deduplicate bib_organismes ALL entry'

UPDATE utilisateurs.bib_organismes SET
    id_organisme = -2,
    nom_organisme = 'ALL (save)'
WHERE id_organisme = 2 ;

UPDATE utilisateurs.bib_organismes SET
    id_organisme = 2,
    nom_organisme = 'ALL',
    additional_data = jsonb_set(
        COALESCE(additional_data, '{}'::jsonb),
        '{migrate2026}',
        jsonb_build_object(
            'uuidOrganismSrc', (SELECT uuid_organisme FROM utilisateurs.bib_organismes WHERE id_organisme = -2)
        )
    )
WHERE id_organisme = 0 AND nom_organisme = 'ALL (temp)';

DELETE FROM utilisateurs.bib_organismes
WHERE id_organisme = -2 AND nom_organisme = 'ALL (save)';

CLUSTER utilisateurs.bib_organismes USING pk_bib_organismes ;


\echo '----------------------------------------------------------------------------'
\echo 'Reset bib_organisme sequence'

SELECT reset_sequence('utilisateurs', 'bib_organismes', 'id_organisme') ;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is OK:'
COMMIT;
