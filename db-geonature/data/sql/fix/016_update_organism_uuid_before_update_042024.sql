--renommer un jeu de données pour permettre l'import correcte en bdd

UPDATE gn_meta.t_datasets AS td SET
    dataset_name = '2022_4_Mignon_Eric',
    dataset_shortname = '2022_4_Mignon_Eric'
WHERE unique_dataset_id = 'bdd422e8-3279-4e5d-8c1c-3b479d13844f' ;

/*
 - Changer la conf dans le fichier /data/cbnmc/config/parser_actions_update.ini
pour permetre la liaison entre les cadres d'acquisition et le JDD avec les UUID
 - Ajouter dans le block dataset : `fk.af = "UUID"`
 - Changer la version de TaxRef
 49         'meta_v_taxref': {
 50             'position': 'after',
 51             'field': 'nom_cite',
 52             'value': '14',	'14' => '16'
 53         },
 - Changer également la version de TaxRef en 16 pour le CBNA
**/

-- Changer des UUID directement en base en se basant sur les noms pour les imports : CBNA et CBNMC (Gentiana)
WITH organisme_tmp(org_uuid, org_nom) AS  ( VALUES
    (
        '0f78faab-c9f2-4437-901a-74df411bc66f'::uuid,
        'Université Claude Bernard Lyon I'
    ),
    (
        '16FBAF09-0B23-452B-98F5-891377D7A7A4'::uuid,
        'Mycea'
    ),
    (
        '4247f5e0-814e-4985-9a5d-99a5bcd938a1'::uuid,
        'Union Européenne'
    ),
    (
        '43360e98-25ef-11ec-af24-005056aa3715'::uuid,
        'Centre Régional de la propriété Forestière Rhône-Alpes'
    ),
    (
        '578B70BC-5247-429E-995E-EB221011A865'::uuid,
        'Ainstants Nature'
    ),
    (
        '5a433bd0-1fc0-25d9-e053-2614a8c026f8'::uuid,
        'Conservatoire botanique national alpin'
    ),
    (
        '5a433bd0-1fcf-25d9-e053-2614a8c026f8'::uuid,
        'Conservatoire du littoral'
    ),
    (
        '5a433bd0-1ff6-25d9-e053-2614a8c026f8'::uuid,
        'Office national des forêts'
    ),
    (
        '5a433bd0-1ffc-25d9-e053-2614a8c026f8'::uuid,
        'Parc national des Ecrins'
    ),
    (
        '5a433bd0-2021-25d9-e053-2614a8c026f8'::uuid,
        'Parc naturel régional du Queyras'
    ),
    (
        '5a433bd0-2106-25d9-e053-2614a8c026f8'::uuid,
        'Les Ecologistes de l''Euzière'
    ),
    (
        '5f832fc3-7e57-3553-e053-2614a8c09903'::uuid,
        'Bureau d''études ECOSPHERE'
    ),
    (
        '62CDA494-5A0B-44E1-E053-2614A8C0FAA0'::uuid,
        'REFORA'
    ),
    (
        '651603cc-e217-7e08-e053-2614a8c06689'::uuid,
        'Nature en Occitanie'
    ),
    (
        '6531e254-8b28-11eb-833a-fab7a7562f4a'::uuid,
        'Institut national de recherche pour l’agriculture, l''alimentation et l''environnement'
    ),
    (
        '69A7E6E8-DC4E-4DA0-8E52-E76A94B1A9C9'::uuid,
        'Communauté de Communes Bugey Sud'
    ),
    (
        '6d5d4426-eb0b-11eb-99fb-005056aa3715'::uuid,
        'Conservatoire d''espaces naturels Occitanie'
    ),
    (
        '814BE156-C05D-408A-A8AD-23E451773C69'::uuid,
        'Commune de Saint-Martin-de-Clelles'
    ),
    (
        '836168e2-6614-4a24-a5eb-5ce47e3512ad'::uuid,
        'Mosaïque Environnement (Agence)'
    ),
    (
        '8600CD0F-9164-4C6B-BA35-51F88A5D78E8'::uuid,
        'Commune de Saint-Martin-d''Uriage'
    ),
    (
        '9377fe7b-7681-4b47-9693-9d9eab7f6b9d'::uuid,
        'MICA Environnement'
    ),
    (
        '9530295e-3f76-4d4d-ae21-acf12be178ff'::uuid,
        'Communauté d''agglomération Porte de l''Isère'
    ),
    (
        '96de4614-1120-4559-8b12-003caa6ad6b3'::uuid,
        'Société Alpine de Protection de la Nature'
    ),
    (
        'a14a142d-a3a3-126f-e053-2614a8c0cfbe'::uuid,
        'Muséum de Grenoble'
    ),
    (
        'AAC77FCA-B52B-4150-996F-C0ACDC7AAD88'::uuid,
        'Fondation Pierre Vérots'
    ),
    (
        'BAE73AA4-13E4-4C19-A487-B026109B7C1F'::uuid,
        'Commune du Cheylas'
    ),
    (
        'bb8a23a0-a0ad-227b-e053-5014a8c06d8b'::uuid,
        'Commune de Chambéry'
    ),
    (
        'bc885784-307d-11ee-944c-005056aa3715'::uuid,
        'Syndicat Mixte pour l''aménagement et la gestion de l''île de Miribel Jonage'
    ),
    (
        'bec7c310-5587-4b77-8d4b-afca524e7d8a'::uuid,
        'Fédération France Orchidées'
    ),
    (
        'd6c288b4-3410-4f5c-83af-c206cd39acdb'::uuid,
        'Syndicat mixte départemental des massifs Concors Sainte-Victoire'
    ),
    (
        'FBA5FF98-13F4-4EED-88C0-D10F9ECB4C00'::uuid,
        'Bureau d''études AMETEN'
    ),
    (
        'bc885784-307d-11ee-944c-005056aa3715'::uuid,
         'Syndicat Mixte pour l’aménagement et la gestion de l’île de Miribel Jonage'
    ),
    (
        'fd12d787-a617-43e1-8c97-f8bafe0f0573'::uuid,
         'Société mycologique de France'
    ),
    (
        '407a7c6e-e83c-46fe-b02a-16157bdeff28'::uuid,
         'Gentiana'
    )
),
rat_org_bdd AS ( /*on enlève les uuid en déjà en bdd */
    SELECT foo.*
    FROM (
            SELECT DISTINCT ON (ot.org_nom) ot.*, bo.id_organisme
            FROM organisme_tmp AS ot
                LEFT JOIN utilisateurs.bib_organismes AS bo
                    ON ot.org_nom = bo.nom_organisme
            WHERE bo.id_organisme IS NOT NULL
                AND bo.uuid_organisme <> ot.org_uuid
            ORDER BY ot.org_nom, bo.id_organisme
        ) AS foo
        LEFT JOIN utilisateurs.bib_organismes AS bo
            ON foo.org_uuid = bo.uuid_organisme
    WHERE bo.id_organisme IS NULL
)
UPDATE utilisateurs.bib_organismes AS porg SET
    uuid_organisme = ot.org_uuid
FROM rat_org_bdd ot
WHERE porg.id_organisme = ot.id_organisme ;

-- Ordre d'intégration obligatoire !!! pour les données de la FMBDS
-- CBNA --> les supprime
-- CBNMC --> les ajoute
