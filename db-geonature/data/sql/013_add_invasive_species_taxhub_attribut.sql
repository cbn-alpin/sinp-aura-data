-- Add new taxa_list_invasive TaxHub attribut with existing thema taxa_lists.
-- Required rights: DB OWNER
-- GeoNature database compatibility : v2.9.2+
--
-- Transfert this script on server with Git or this way:
--      rsync -av ./013_* geonat@db-aura-sinp:~/data/db-geonature/data/sql/ --dry-run
-- Use this script this way:
--      cat ./013_* | sed 's#${csvDirectory}#/path/to/db-geonature/csv/directory#g'| \
--      psql -h localhost -U geonatadmin -d geonature2db
-- Then :
--      - update your "geonature_config.toml" file to set ID_ATTRIBUT_TAXHUB parameter
--      - activate GeoNature venv
--      - update configuration with : `geonature update-configuration`
--      - restart GeoNature systemd service : `sudo systemctl restart geonature`


BEGIN ;


\echo '----------------------------------------------------------------------------'
\echo 'Create function get_id_theme_by_name'

DROP FUNCTION IF EXISTS taxonomie.get_id_theme_by_name(varchar) ;

CREATE OR REPLACE FUNCTION taxonomie.get_id_theme_by_name(themeName varchar)
 RETURNS integer
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
    -- Function which return the id_theme from Taxhub Attributs theme
    DECLARE idTheme integer;

    BEGIN
        SELECT INTO idTheme id_theme
        FROM taxonomie.bib_themes
        WHERE nom_theme = themeName ;

        RETURN idTheme ;
    END;
$function$ ;


\echo '-------------------------------------------------------------------------------'
\echo 'Create temporary taxa lists import table'
DROP TABLE IF EXISTS gn_imports.taxa_lists ;

CREATE TABLE gn_imports.taxa_lists AS
    SELECT
        NULL::INT AS gid,
        NULL::INT AS cd_nom,
        NULL::VARCHAR(250) AS taxa_name,
        NULL::VARCHAR(50) AS group
WITH NO DATA ;

CREATE SEQUENCE gn_imports.taxa_lists_seq AS integer START 1 OWNED BY gn_imports.taxa_lists.gid;
ALTER TABLE gn_imports.taxa_lists ALTER COLUMN gid SET DEFAULT nextval('gn_imports.taxa_lists_seq');

\echo '-------------------------------------------------------------------------------'
\echo 'Copy Invasive Flora CVS file to temporary import table'
ALTER TABLE gn_imports.taxa_lists ALTER COLUMN "group" SET DEFAULT 'Flora';

COPY gn_imports.taxa_lists (
    cd_nom,
    taxa_name
)
FROM '${csvDirectory}/taxa_list_invasive_flora.csv'
WITH CSV HEADER DELIMITER E'\t' NULL '\N' ;

ALTER TABLE gn_imports.taxa_lists ALTER COLUMN "group" DROP DEFAULT;


\echo '-------------------------------------------------------------------------------'
\echo 'Copy Invasive Flora CVS file to temporary import table'
ALTER TABLE gn_imports.taxa_lists ALTER COLUMN "group" SET DEFAULT 'Fauna';

COPY gn_imports.taxa_lists (
    cd_nom,
    taxa_name
)
FROM '${csvDirectory}/taxa_list_invasive_fauna.csv'
WITH CSV HEADER DELIMITER E'\t' NULL '\N' ;

ALTER TABLE gn_imports.taxa_lists ALTER COLUMN "group" DROP DEFAULT;


\echo '----------------------------------------------------------------------------'
\echo 'Delete all previous taxa_lists_invasive topic data'
DELETE FROM taxonomie.cor_taxon_attribut
WHERE id_attribut IN (
    SELECT id_attribut
    FROM taxonomie.bib_attributs
    WHERE nom_attribut = 'taxa_lists_invasive'
) ;

DELETE FROM taxonomie.bib_attributs
WHERE nom_attribut = 'taxa_lists_invasive' ;


\echo '----------------------------------------------------------------------------'
\echo 'Create TaxHub attributs'
INSERT INTO taxonomie.bib_attributs (
    nom_attribut,
    label_attribut,
    liste_valeur_attribut,
    obligatoire,
    desc_attribut,
    type_attribut,
    type_widget,
    id_theme,
    ordre
) VALUES (
    'taxa_lists_invasive',
    'Espèces exotiques envahissantes',
    '{"values": ["Espèces végétales exotiques envahissantes", "Espèces animales exotiques envahissantes"]}',
    false,
    'Listes de taxons exotiques envahissants réglementés.',
    'text',
    'multiselect',
    taxonomie.get_id_theme_by_name('taxa_lists'),
    2
) ON CONFLICT (nom_attribut) DO NOTHING ;


\echo '----------------------------------------------------------------------------'
\echo 'Associate TaxHub attribut taxa_lists_invasive="Flora" to taxons'
INSERT INTO taxonomie.cor_taxon_attribut (
    id_attribut,
    valeur_attribut,
    cd_ref
)
    SELECT DISTINCT
        taxonomie.get_id_attribut_by_name('taxa_lists_invasive'),
        'Flora',
        t.cd_ref
    FROM taxonomie.taxref AS t
    WHERE t.cd_nom IN (
        SELECT cd_nom
        FROM gn_imports.taxa_lists
        WHERE "group" = 'Flora'
    ) ;


\echo '----------------------------------------------------------------------------'
\echo 'Associate TaxHub attribut taxa_lists_invasive="Fauna" to taxons'
INSERT INTO taxonomie.cor_taxon_attribut (
    id_attribut,
    valeur_attribut,
    cd_ref
)
    SELECT DISTINCT
        taxonomie.get_id_attribut_by_name('taxa_lists_invasive'),
        'Fauna',
        t.cd_ref
    FROM taxonomie.taxref AS t
    WHERE t.cd_nom IN (
        SELECT cd_nom
        FROM gn_imports.taxa_lists
        WHERE "group" = 'Fauna'
    ) ;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is OK:'
COMMIT ;
