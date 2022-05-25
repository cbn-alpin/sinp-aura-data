-- Suppression de toutes les données de la LPO + l'utilisateur importé lors de
-- la transmission de données de 2021.
-- Si la table `gn2pg_lpo.data_json` existe, les triggers sont déclenchés.
-- Usage: psql -h "localhost" -U "<db-owner-name>" -d "<db-name>" -f <path-to-this-sql-file>
-- Ex.: psql -h "localhost" -U "geonatadmin" -d "geonature2db" -f ~/data/lpo/data/sql/update/001_*

BEGIN ;

CREATE TEMPORARY TABLE delete_acquisition_frameworks (
    unique_acquisition_framework uuid,
    primary key (unique_acquisition_framework)
) ;
INSERT INTO delete_acquisition_frameworks (unique_acquisition_framework)
VALUES ('e7935970-de15-4db4-a723-466f68844a67');

DELETE FROM gn_synthese.cor_area_synthese AS a
USING gn_synthese.synthese AS s,
    gn_meta.t_datasets AS td,
    gn_meta.t_acquisition_frameworks AS af,
    delete_acquisition_frameworks AS df
WHERE a.id_synthese = s.id_synthese
    AND s.id_dataset = td.id_dataset
    AND td.id_acquisition_framework = af.id_acquisition_framework
    AND af.unique_acquisition_framework_id = df.unique_acquisition_framework ;

DELETE FROM gn_synthese.synthese AS s
USING  gn_meta.t_datasets AS td,
    gn_meta.t_acquisition_frameworks AS af,
    delete_acquisition_frameworks AS df
WHERE s.id_dataset = td.id_dataset
    AND td.id_acquisition_framework = af.id_acquisition_framework
    AND af.unique_acquisition_framework_id = df.unique_acquisition_framework ;

DELETE FROM gn_synthese.t_sources AS sou
USING gn_synthese.synthese AS s
WHERE sou.id_source = s.id_source
    AND s.id_synthese IS NULL;

DELETE FROM gn_meta.cor_dataset_actor AS ac
USING  gn_meta.t_datasets AS td,
    gn_meta.t_acquisition_frameworks AS af,
    delete_acquisition_frameworks AS df
WHERE ac.id_dataset = td.id_dataset
    AND td.id_acquisition_framework = af.id_acquisition_framework
    AND af.unique_acquisition_framework_id = df.unique_acquisition_framework ;

DELETE FROM gn_meta.cor_dataset_territory AS te
USING  gn_meta.t_datasets AS td,
    gn_meta.t_acquisition_frameworks AS af,
    delete_acquisition_frameworks AS df
WHERE te.id_dataset = td.id_dataset
    AND td.id_acquisition_framework = af.id_acquisition_framework
    AND af.unique_acquisition_framework_id = df.unique_acquisition_framework ;

DELETE FROM gn_meta.cor_dataset_protocol AS pro
USING  gn_meta.t_datasets AS td,
    gn_meta.t_acquisition_frameworks AS af,
    delete_acquisition_frameworks AS df
WHERE pro.id_dataset = td.id_dataset
    AND td.id_acquisition_framework = af.id_acquisition_framework
    AND af.unique_acquisition_framework_id = df.unique_acquisition_framework ;

DELETE FROM gn_meta.t_datasets AS td
USING gn_meta.t_acquisition_frameworks af, delete_acquisition_frameworks AS df
WHERE  td.id_acquisition_framework = af.id_acquisition_framework
    AND af.unique_acquisition_framework_id = df.unique_acquisition_framework ;

DELETE FROM gn_meta.cor_acquisition_framework_actor AS ac
USING  gn_meta.t_acquisition_frameworks AS af, delete_acquisition_frameworks AS df
WHERE ac.id_acquisition_framework = af.id_acquisition_framework
    AND af.unique_acquisition_framework_id = df.unique_acquisition_framework ;

DELETE FROM gn_meta.cor_acquisition_framework_objectif AS obj
USING  gn_meta.t_acquisition_frameworks AS af, delete_acquisition_frameworks AS df
WHERE obj.id_acquisition_framework = af.id_acquisition_framework
    AND af.unique_acquisition_framework_id = df.unique_acquisition_framework ;

DELETE FROM gn_meta.cor_acquisition_framework_publication AS pub
USING  gn_meta.t_acquisition_frameworks AS af, delete_acquisition_frameworks AS df
WHERE pub.id_acquisition_framework = af.id_acquisition_framework
    AND af.unique_acquisition_framework_id = df.unique_acquisition_framework ;

DELETE FROM gn_meta.cor_acquisition_framework_voletsinp AS si
USING  gn_meta.t_acquisition_frameworks AS af, delete_acquisition_frameworks AS df
WHERE si.id_acquisition_framework = af.id_acquisition_framework
    AND af.unique_acquisition_framework_id = df.unique_acquisition_framework ;

DELETE FROM gn_meta.t_acquisition_frameworks AS af
USING delete_acquisition_frameworks AS df
WHERE af.unique_acquisition_framework_id = df.unique_acquisition_framework ;

DELETE FROM utilisateurs.cor_roles AS cr
USING utilisateurs.t_roles AS r
WHERE cr.id_role_utilisateur = r.id_role
    AND uuid_role = '14092bda-9d95-4e1c-9cd0-29f28a8f91cf';

DELETE FROM utilisateurs.t_roles WHERE uuid_role = '14092bda-9d95-4e1c-9cd0-29f28a8f91cf';

DO $$
    BEGIN
        IF EXISTS
            ( SELECT 1
                FROM   information_schema.tables
                WHERE  table_schema = 'gn2pg_lpo'
                AND    table_name = 'data_json'
            )
        THEN
            UPDATE gn2pg_lpo.data_json
            SET id_data = id_data ;
        END IF ;
    END
$$ ;

COMMIT;
