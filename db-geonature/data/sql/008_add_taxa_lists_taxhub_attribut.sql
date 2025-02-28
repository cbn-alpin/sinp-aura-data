-- Add new taxa_list_messicole TaxHub attribut with new thema taxa_lists.
-- Required rights: DB OWNER
-- GeoNature database compatibility : v2.9.2+
--
-- Transfert this script on server with Git or this way:
--      rsync -av ./008_* geonat@db-aura-sinp:~/data/db-geonature/data/sql/ --dry-run
-- Use this script this way:
--      cat ./008_* | sed 's#${csvDirectory}#/path/to/db-geonature/csv/directory#g'| \
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
\echo 'Copy Messicole plants CVS file to temporary import table'
ALTER TABLE gn_imports.taxa_lists ALTER COLUMN "group" SET DEFAULT 'Messicole';

COPY gn_imports.taxa_lists (
    cd_nom,
    taxa_name
)
FROM '${csvDirectory}/taxa_list_messicole_plants.csv'
WITH CSV HEADER DELIMITER E'\t' NULL '\N' ;

ALTER TABLE gn_imports.taxa_lists ALTER COLUMN "group" DROP DEFAULT;


\echo '----------------------------------------------------------------------------'
\echo 'Delete all previous taxa_lists topic data'
DELETE FROM taxonomie.cor_taxon_attribut
WHERE id_attribut IN (
    SELECT id_attribut
    FROM taxonomie.bib_attributs
    WHERE id_theme = taxonomie.get_id_theme_by_name('taxa_lists')
) ;

DELETE FROM taxonomie.bib_attributs
WHERE id_theme = taxonomie.get_id_theme_by_name('taxa_lists') ;


\echo '----------------------------------------------------------------------------'
\echo 'Create TaxHub attributes topic'
INSERT taxonomie.bib_themes (
    nom_theme,
    desc_theme
) VALUES (
    'taxa_lists',
    'Groupement de taxons selon un thème non taxonomique.'
) ON CONFLICT (nom_theme) DO NOTHING ;


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
    'taxa_lists_flora',
    'Listes flore thématiques',
    '{"values": ["Messicole"]}',
    false,
    'Listes thématiques de taxons pour la flore.',
    'text',
    'multiselect',
    taxonomie.get_id_theme_by_name('taxa_lists'),
    1
) ON CONFLICT (nom_attribut) DO NOTHING ;


\echo '----------------------------------------------------------------------------'
\echo 'Associate TaxHub attribut taxa_lists_flora="Messicole" to taxons'
INSERT INTO taxonomie.cor_taxon_attribut (
    id_attribut,
    valeur_attribut,
    cd_ref
)
    SELECT DISTINCT
        taxonomie.get_id_attribut_by_name('taxa_lists_flora'),
        'Messicole',
        t.cd_ref
    FROM taxonomie.taxref AS t
    WHERE t.cd_nom IN (
        SELECT cd_nom
        FROM gn_imports.taxa_lists
        WHERE "group" = 'Messicole'
    ) ;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is OK:'
COMMIT ;
