-- Migrate to GeoNature v2.16/2.17
-- Clean all necessary tables before migration in source db

BEGIN;


\echo '----------------------------------------------------------------------------'
\echo 'Update orgnism names to avoid duplicate entries on bib_organismes table'

UPDATE utilisateurs.bib_organismes AS bo SET
    nom_organisme = 'France Nature Environnement Ain (doublon1)'
WHERE bo.uuid_organisme = 'a6bf71e1-f505-4353-a3bb-3635ebf687c3';
UPDATE utilisateurs.bib_organismes AS bo SET
    nom_organisme = 'France Nature Environnement Ain (doublon2)'
WHERE bo.uuid_organisme = '4adb9cf6-4aac-4aae-846c-7f94697f0793';

UPDATE utilisateurs.bib_organismes AS bo SET
    nom_organisme = 'Syndicat de Rivières les Usses (doublon)'
WHERE bo.uuid_organisme = '238d7816-c1aa-4f88-a6a4-8f2887c4e513';

UPDATE utilisateurs.bib_organismes AS bo SET
    nom_organisme = 'Syndicat du Haut Rhône (doublon)'
WHERE bo.uuid_organisme = 'bf03008b-228d-491f-a59a-5c19281465a6';

UPDATE utilisateurs.bib_organismes AS bo SET
    nom_organisme = 'CF ENVIRONNEMENT (doublon)'
WHERE bo.uuid_organisme = 'db3cc500-564e-4578-bbb2-3b6ed9bf3c8c';

UPDATE utilisateurs.bib_organismes AS bo SET
    nom_organisme = 'Département de la Loire (doublon)'
WHERE bo.uuid_organisme = '57ba0493-75c3-4d85-8461-f1c661cd8d4c';

UPDATE utilisateurs.bib_organismes AS bo SET
    nom_organisme = 'MICA Environnement (doublon1)'
WHERE bo.uuid_organisme = 'eec50cb8-f640-4d81-b75b-df1d2399a820';
UPDATE utilisateurs.bib_organismes AS bo SET
    nom_organisme = 'MICA Environnement (doublon2)'
WHERE bo.uuid_organisme = '000bfa26-d3c6-4c98-9d2f-92eb5ec59756';

UPDATE utilisateurs.bib_organismes AS bo SET
    nom_organisme = 'Agence de l''eau Rhône Méditerranée Corse (doublon)'
WHERE bo.uuid_organisme = 'efa9169a-6df2-49c2-aec6-966fde1b71d0';

UPDATE utilisateurs.bib_organismes AS bo SET
    nom_organisme = 'SOCOTEC (doublon)'
WHERE bo.uuid_organisme = '6a030285-5c25-4795-92da-91c0f968d0e1';

UPDATE utilisateurs.bib_organismes AS bo SET
    nom_organisme = 'DREAL Auvergne-Rhône-Alpes (doublon)'
WHERE bo.uuid_organisme = 'eb3b2700-a29e-4d5a-9223-30a2842727b5';

UPDATE utilisateurs.bib_organismes AS bo SET
    nom_organisme = 'Conservatoire d''Espaces Naturels d''Auvergne (doublon)'
WHERE bo.uuid_organisme = '9c848722-dc95-41d8-95a6-661a5e1d841f';

UPDATE utilisateurs.bib_organismes AS bo SET
    nom_organisme = 'DREAL Centre-Val de Loire (antenne Orléans)'
WHERE bo.uuid_organisme = '5a433bd0-1fa8-25d9-e053-2614a8c026f8';

UPDATE utilisateurs.bib_organismes AS bo SET
    nom_organisme = 'Office français de la biodiversité (doublon1)'
WHERE bo.uuid_organisme = '07c62935-2d06-4c4d-a738-8409e5ff7376';
UPDATE utilisateurs.bib_organismes AS bo SET
    nom_organisme = 'Office français de la biodiversité (doublon2)'
WHERE bo.uuid_organisme = '4ed91be5-34e3-4219-b3e4-a9bd67c2497d';

UPDATE utilisateurs.bib_organismes AS bo SET
    nom_organisme = 'CPIE Haute-Auvergne (doublon)'
WHERE bo.uuid_organisme = '32d394ec-d807-4542-9129-a2ebdbc46fd8';

UPDATE utilisateurs.bib_organismes AS bo SET
    nom_organisme = 'Métropole de Lyon (doublon)'
WHERE bo.uuid_organisme = 'b54db10a-faf3-466c-a05b-362f14a41e3d';

UPDATE utilisateurs.bib_organismes AS bo SET
    nom_organisme = 'Département de la Drôme (doublon)'
WHERE bo.uuid_organisme = 'd777bf9b-faa0-4860-a6f6-c81b9c618974';

UPDATE utilisateurs.bib_organismes AS bo SET
    nom_organisme = 'TEREO (doublon)'
WHERE bo.uuid_organisme = '320bc56c-c927-4464-8f05-c2b14b3d13b4';

UPDATE utilisateurs.bib_organismes AS bo SET
    nom_organisme = 'Arthropologia (doublon1)'
WHERE bo.uuid_organisme = 'ae0c89d2-1669-4f11-a008-1820fa5400f5';
UPDATE utilisateurs.bib_organismes AS bo SET
    nom_organisme = 'Arthropologia (doublon2)'
WHERE bo.uuid_organisme = '266b049e-7968-402c-be94-c580f95be5fd';

UPDATE utilisateurs.bib_organismes AS bo SET
    nom_organisme = 'Communauté des Communes du Diois (doublon)'
WHERE bo.uuid_organisme = '308aa8c6-3aeb-4b22-94f9-7adbd263f5e1';

UPDATE utilisateurs.bib_organismes AS bo SET
    nom_organisme = 'BORALEX (doublon)'
WHERE bo.uuid_organisme = '88424e66-468c-4598-9df2-3a856bfded77';

UPDATE utilisateurs.bib_organismes AS bo SET
    nom_organisme = 'Parc national des Ecrins (doublon)'
WHERE bo.uuid_organisme = '2b5c005b-cb2c-477c-9134-9b07b9747e5b';

UPDATE utilisateurs.bib_organismes AS bo SET
    nom_organisme = 'Conseil Départemental de l''Isère (doublon1)'
WHERE bo.uuid_organisme = 'eaf33809-9bd9-462c-991a-2187d473bcd0';
UPDATE utilisateurs.bib_organismes AS bo SET
    nom_organisme = 'Conseil Départemental de l''Isère (doublon2)'
WHERE bo.uuid_organisme = 'd52df58e-f9bb-4e93-9ea4-c976eeb5323d';

UPDATE utilisateurs.bib_organismes AS bo SET
    nom_organisme = 'ALL (doublon)'
WHERE bo.uuid_organisme = '921d90c0-8ad6-4646-8636-2f08886bed91';

UPDATE utilisateurs.bib_organismes AS bo SET
    nom_organisme = 'Autre (doublon1)'
WHERE bo.uuid_organisme = 'd62b0077-9176-4899-87b5-ba39c3aeeba4';
UPDATE utilisateurs.bib_organismes AS bo SET
    nom_organisme = 'Autre (doublon2)'
WHERE bo.uuid_organisme = '1e85715c-0dfe-4ef3-8033-a81af2abb9c0';
UPDATE utilisateurs.bib_organismes AS bo SET
    nom_organisme = 'Autre (doublon3)'
WHERE bo.uuid_organisme = 'd9ed7f9a-68e4-4f5b-8847-11321fccb556';
UPDATE utilisateurs.bib_organismes AS bo SET
    nom_organisme = 'Autre (doublon4)'
WHERE bo.uuid_organisme = '601d8e19-4908-4a7a-8f09-627c4c296d7e';
UPDATE utilisateurs.bib_organismes AS bo SET
    nom_organisme = 'Autre (doublon5)'
WHERE bo.uuid_organisme = '9b25de50-8f1a-44bf-b7d9-0ab1a4f4efbb';
UPDATE utilisateurs.bib_organismes AS bo SET
    nom_organisme = 'Autre (doublon6)'
WHERE bo.uuid_organisme = '081067bf-c9ea-40be-b56b-614c6114f0d1';

UPDATE utilisateurs.bib_organismes AS bo SET
    nom_organisme = 'Conservatoire d''Espaces Naturels de l''Allier (doublon)'
WHERE bo.uuid_organisme = '64bd1f0f-e4a0-420b-bc1f-2a4659701f7f';

UPDATE utilisateurs.bib_organismes AS bo SET
    nom_organisme = 'Indépendant (doublon)'
WHERE bo.uuid_organisme = 'fdfed70e-c5aa-440f-b5b6-470e9d2977f3';

UPDATE utilisateurs.bib_organismes AS bo SET
    nom_organisme = 'Parc Naturel Régional de Chartreuse (doublon)'
WHERE bo.uuid_organisme = '5730955a-588a-4b80-9919-56a62db141bc';

UPDATE utilisateurs.bib_organismes AS bo SET
    nom_organisme = 'Apollon 74 (doublon1)'
WHERE bo.uuid_organisme = '78de10cd-5bbc-4bbb-ac7a-1a2025d5f17a';
UPDATE utilisateurs.bib_organismes AS bo SET
    nom_organisme = 'Apollon 74 (doublon2)'
WHERE bo.uuid_organisme = '90733d44-4ef0-4f05-93cc-515f22061bf0';

UPDATE utilisateurs.bib_organismes AS bo SET
    nom_organisme = 'Département du Rhône (doublon)'
WHERE bo.uuid_organisme = 'b51e8af2-9117-4ab9-a1fc-1d84b994364f';

UPDATE utilisateurs.bib_organismes AS bo SET
    nom_organisme = 'Association - Flavia APE (doublon)'
WHERE bo.uuid_organisme = 'bb00ee2a-f372-47de-bb54-1fffa594e412';

UPDATE utilisateurs.bib_organismes AS bo SET
    nom_organisme = 'Grenoble Alpes Metropole (doublon)'
WHERE bo.uuid_organisme = '82e9ac06-704b-468c-8891-e372cc0a16fb';

UPDATE utilisateurs.bib_organismes AS bo SET
    nom_organisme = 'Moulins Communauté (doublon)'
WHERE bo.uuid_organisme = '9f74fc2b-8065-491b-8e5a-9f734cbc5b92';

UPDATE utilisateurs.bib_organismes AS bo SET
    nom_organisme = 'Union Européenne (doublon)'
WHERE bo.uuid_organisme = '58b4e0ce-2423-498c-83dd-ef1e1f7ba26e';


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is OK:'
COMMIT ;
