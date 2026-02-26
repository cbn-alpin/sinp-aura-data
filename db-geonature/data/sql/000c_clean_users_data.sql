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
\echo 'COMMIT if all is OK:'
COMMIT ;
