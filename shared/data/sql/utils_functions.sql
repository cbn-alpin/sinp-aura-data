\echo 'Insert utils functions'
\echo 'Required rights: db owner'
\echo 'GeoNature database compatibility : v2.3.0+'
BEGIN;


\echo '-------------------------------------------------------------------------------'
\echo 'Set function "get_id_area_type_by_code()"'
CREATE OR REPLACE FUNCTION ref_geo.get_id_area_type_by_code(areaTypeCode character varying)
    RETURNS integer
    LANGUAGE plpgsql
    IMMUTABLE
AS
$function$
    -- Function which return the id_type from a bib_areas_types
    DECLARE idType integer;

    BEGIN
        SELECT INTO idType id_type
        FROM ref_geo.bib_areas_types AS bat
        WHERE bat.type_code = areaTypeCode ;

        RETURN idType ;
    END;
$function$ ;


\echo '-------------------------------------------------------------------------------'
\echo 'Set function "get_id_acquisition_framework_by_name()"'
CREATE OR REPLACE FUNCTION gn_meta.get_id_acquisition_framework_by_name(afName character varying)
    RETURNS integer
    LANGUAGE plpgsql
    IMMUTABLE
AS
$function$
    -- Function which return the id_acquisition_framework from an acquition_framework_name
    DECLARE idAcquisitionFramework integer;

    BEGIN
        SELECT INTO idAcquisitionFramework id_acquisition_framework
        FROM gn_meta.t_acquisition_frameworks AS af
        WHERE af.acquisition_framework_name = afName ;

        RETURN idAcquisitionFramework ;
    END;
$function$ ;


\echo '-------------------------------------------------------------------------------'
\echo 'Set function "get_id_acquisition_framework_by_uuid()"'
CREATE OR REPLACE FUNCTION gn_meta.get_id_acquisition_framework_by_uuid(afUuid uuid)
    RETURNS integer
    LANGUAGE plpgsql
    IMMUTABLE
AS
$function$
    -- Function which return the id_acquisition_framework from an unique_acquisition_framework_id
    DECLARE idAcquisitionFramework integer;

    BEGIN
        SELECT INTO idAcquisitionFramework id_acquisition_framework
        FROM gn_meta.t_acquisition_frameworks AS af
        WHERE af.unique_acquisition_framework_id = afUuid ;

        RETURN idAcquisitionFramework ;
    END;
$function$ ;


\echo '-------------------------------------------------------------------------------'
\echo 'Set function "get_id_dataset_by_shortname()"'
CREATE OR REPLACE FUNCTION gn_meta.get_id_dataset_by_shortname(shortName character varying)
    RETURNS integer
    LANGUAGE plpgsql
    IMMUTABLE
AS
$function$
    -- Function which return the id_dataset from an dataset_shortname
    DECLARE idDataset integer;

    BEGIN
        SELECT INTO idDataset id_dataset
        FROM gn_meta.t_datasets AS td
        WHERE td.dataset_shortname = shortName ;

        RETURN idDataset ;
    END;
$function$ ;


\echo '-------------------------------------------------------------------------------'
\echo 'Set function "get_id_dataset_by_uuid()"'
CREATE OR REPLACE FUNCTION gn_meta.get_id_dataset_by_uuid(dUuid uuid)
    RETURNS integer
    LANGUAGE plpgsql
    IMMUTABLE
AS
$function$
    -- Function which return the id_dataset from an unique_dataset_id
    DECLARE idDataset integer;

    BEGIN
        SELECT INTO idDataset id_dataset
        FROM gn_meta.t_datasets AS td
        WHERE td.unique_dataset_id = dUuid ;

        RETURN idDataset ;
    END;
$function$ ;


\echo '-------------------------------------------------------------------------------'
\echo 'Set function "get_id_organism_by_name()"'
CREATE OR REPLACE FUNCTION utilisateurs.get_id_organism_by_name(oName character varying)
    RETURNS integer
    LANGUAGE plpgsql
    IMMUTABLE
AS
$function$
    -- Function which return the id_organisme from an nom_organisme
    DECLARE idOrganism integer;

    BEGIN
        SELECT INTO idOrganism id_organisme
        FROM utilisateurs.bib_organismes AS bo
        WHERE bo.nom_organisme = oName ;

        RETURN idOrganism ;
    END;
$function$ ;


\echo '-------------------------------------------------------------------------------'
\echo 'Set function "get_id_organism_by_uuid()"'
CREATE OR REPLACE FUNCTION utilisateurs.get_id_organism_by_uuid(oUuid uuid)
    RETURNS integer
    LANGUAGE plpgsql
    IMMUTABLE
AS
$function$
    -- Function which return the id_organisme from an uuid_organisme
    DECLARE idOrganism integer;

    BEGIN
        SELECT INTO idOrganism id_organisme
        FROM utilisateurs.bib_organismes AS bo
        WHERE bo.uuid_organisme = oUuid ;

        RETURN idOrganism ;
    END;
$function$ ;


\echo '-------------------------------------------------------------------------------'
\echo 'Set function "get_id_role_by_identifier()"'
CREATE OR REPLACE FUNCTION utilisateurs.get_id_role_by_identifier(identifier character varying)
    RETURNS integer
    LANGUAGE plpgsql
    IMMUTABLE
AS
$function$
    -- Function which return the id_role from an identifiant
    DECLARE idRole integer;

    BEGIN
        SELECT INTO idRole id_role
        FROM utilisateurs.t_roles AS tr
        WHERE tr.identifiant = identifier ;

        RETURN idRole ;
    END;
$function$ ;


\echo '-------------------------------------------------------------------------------'
\echo 'Set function "get_id_role_by_uuid()"'
CREATE OR REPLACE FUNCTION utilisateurs.get_id_role_by_uuid(rUuid uuid)
    RETURNS integer
    LANGUAGE plpgsql
    IMMUTABLE
AS
$function$
    -- Function which return the id_role from an uuid_role
    DECLARE idRole integer;

    BEGIN
        SELECT INTO idRole id_role
        FROM utilisateurs.t_roles AS tr
        WHERE tr.uuid_role = rUuid ;

        RETURN idRole ;
    END;
$function$ ;


\echo '-------------------------------------------------------------------------------'
\echo 'Set function "get_id_source_by_name()"'
CREATE OR REPLACE FUNCTION gn_synthese.get_id_source_by_name(sourceName character varying)
    RETURNS integer
    LANGUAGE plpgsql
    IMMUTABLE
AS
$function$
    -- Function which return the id_source from an name_source
    DECLARE idSource integer;

    BEGIN
        SELECT INTO idSource id_source
        FROM gn_synthese.t_sources AS ts
        WHERE ts.name_source = sourceName ;

        RETURN idSource ;
    END;
$function$ ;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
