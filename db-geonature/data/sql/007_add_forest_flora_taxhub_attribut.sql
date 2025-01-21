-- Add new forest_flora_priority TaxHub attribut with new thema forest_flora.
-- Required rights: DB OWNER
-- GeoNature database compatibility : v2.9.2+
-- Transfert this script on server with Git or this way:
-- rsync -av ./007_* geonat@db-aura-sinp:~/data/db-geonature/data/sql/ --dry-run
-- Use this script this way:
--      cat ./007_* | sed 's#${csvDirectory}#/path/to/db-geonature/csv/directory#g'| \
--      psql -h localhost -U geonatadmin -d geonature2db

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
\echo 'Create temporary priority forest flora import table'
DROP TABLE IF EXISTS gn_imports.piority_forest_flora ;

CREATE TABLE gn_imports.piority_forest_flora AS
    SELECT
        NULL::INT AS gid,
        NULL::INT AS cd_nom,
        NULL::VARCHAR(250) AS taxa_name,
        NULL::VARCHAR(50) AS group,
        NULL::BOOLEAN AS level_1_alp,
        NULL::BOOLEAN AS level_1_mc,
        NULL::BOOLEAN AS level_2_alp,
        NULL::BOOLEAN AS level_2_mc
WITH NO DATA ;

CREATE SEQUENCE gn_imports.priority_forest_flora_seq AS integer START 1 OWNED BY gn_imports.piority_forest_flora.gid;
ALTER TABLE gn_imports.piority_forest_flora ALTER COLUMN gid SET DEFAULT nextval('gn_imports.priority_forest_flora_seq');

\echo '-------------------------------------------------------------------------------'
\echo 'Copy Tracheophyta CVS file to temporary import table'
ALTER TABLE gn_imports.piority_forest_flora ALTER COLUMN "group" SET DEFAULT 'Tracheophyta';

COPY gn_imports.piority_forest_flora (
    cd_nom,
    taxa_name,
    level_1_alp,
    level_1_mc,
    level_2_alp,
    level_2_mc
)
FROM '${csvDirectory}/priority_forest_flora_tracheophyta.csv'
WITH CSV HEADER DELIMITER E'\t' NULL '\N' ;


\echo '-------------------------------------------------------------------------------'
\echo 'Copy Bryophyta CVS file to temporary import table'
ALTER TABLE gn_imports.piority_forest_flora ALTER COLUMN "group" SET DEFAULT 'Bryophyta';

COPY gn_imports.piority_forest_flora (
    cd_nom,
    taxa_name,
    level_1_alp,
    level_1_mc
)
FROM '${csvDirectory}/priority_forest_flora_bryophyta.csv'
WITH CSV HEADER DELIMITER E'\t' NULL '\N' ;

ALTER TABLE gn_imports.piority_forest_flora ALTER COLUMN "group" DROP DEFAULT;


\echo '----------------------------------------------------------------------------'
\echo 'Delete all previous forest_flora topic data'

DELETE FROM taxonomie.cor_taxon_attribut
WHERE id_attribut IN (
    SELECT id_attribut
    FROM taxonomie.bib_attributs
    WHERE id_theme = taxonomie.get_id_theme_by_name('forest_flora')
) ;

DELETE FROM taxonomie.bib_attributs
WHERE id_theme = taxonomie.get_id_theme_by_name('forest_flora') ;


\echo '----------------------------------------------------------------------------'
\echo 'Create TaxHub attributes topic'
-- Change "Mon territoire" default not used theme to "forest_flora" topic
UPDATE taxonomie.bib_themes SET
    nom_theme = 'forest_flora',
    desc_theme =  'Informations relatives à la flore forestière.'
WHERE nom_theme = 'Mon territoire' ;


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
    'forest_flora_priority',
    'Flore forestière prioritaire',
    '{"values": ["Trachéophytes - Enjeu 1 Alpes", "Trachéophytes - Enjeu 2 Alpes", "Trachéophytes - Enjeu 1 Massif Central", "Trachéophytes - Enjeu 2 Massif Central", "Bryophytes - Alpes", "Bryophytes - Massif Central"]}',
    false,
    'Priorité des taxons de la flore forestière sur la région AURA.',
    'text',
    'multiselect',
    taxonomie.get_id_theme_by_name('forest_flora'),
    1
) ON CONFLICT (nom_attribut) DO NOTHING ;


\echo '----------------------------------------------------------------------------'
\echo 'Associate TaxHub attribut forest_flora_priority="Trachéophytes - Enjeu 1 Alpes" to taxons'
INSERT INTO taxonomie.cor_taxon_attribut (
    id_attribut,
    valeur_attribut,
    cd_ref
)
    SELECT DISTINCT
        taxonomie.get_id_attribut_by_name('forest_flora_priority'),
        'Trachéophytes - Enjeu 1 Alpes',
        t.cd_ref
    FROM taxonomie.taxref AS t
    WHERE t.cd_nom IN (
        SELECT cd_nom
        FROM gn_imports.piority_forest_flora
        WHERE "group" = 'Tracheophyta'
            AND level_1_alp = TRUE
    ) ;


\echo '----------------------------------------------------------------------------'
\echo 'Associate TaxHub attribut forest_flora_priority_tracheophyta="Trachéophytes - Enjeu 2 Alpes" to taxons'
INSERT INTO taxonomie.cor_taxon_attribut (
    id_attribut,
    valeur_attribut,
    cd_ref
)
    SELECT DISTINCT
        taxonomie.get_id_attribut_by_name('forest_flora_priority'),
        'Trachéophytes - Enjeu 2 Alpes',
        t.cd_ref
    FROM taxonomie.taxref AS t
    WHERE t.cd_nom IN (
        SELECT cd_nom
        FROM gn_imports.piority_forest_flora
        WHERE "group" = 'Tracheophyta'
            AND level_2_alp = TRUE
    )
ON CONFLICT (id_attribut, cd_ref) DO UPDATE
SET valeur_attribut = CONCAT_WS(
    '&',
    taxonomie.cor_taxon_attribut.valeur_attribut,
    EXCLUDED.valeur_attribut
) ;


\echo '----------------------------------------------------------------------------'
\echo 'Associate TaxHub attribut forest_flora_priority_tracheophyta="Trachéophytes - Enjeu 1 Massif Central" to taxons'
INSERT INTO taxonomie.cor_taxon_attribut (
    id_attribut,
    valeur_attribut,
    cd_ref
)
    SELECT DISTINCT
        taxonomie.get_id_attribut_by_name('forest_flora_priority'),
        'Trachéophytes - Enjeu 1 Massif Central',
        t.cd_ref
    FROM taxonomie.taxref AS t
    WHERE t.cd_nom IN (
        SELECT cd_nom
        FROM gn_imports.piority_forest_flora
        WHERE "group" = 'Tracheophyta'
            AND level_1_mc = TRUE
    )
ON CONFLICT (id_attribut, cd_ref) DO UPDATE
SET valeur_attribut = CONCAT_WS(
    '&',
    taxonomie.cor_taxon_attribut.valeur_attribut,
    EXCLUDED.valeur_attribut
) ;


\echo '----------------------------------------------------------------------------'
\echo 'Associate TaxHub attribut forest_flora_priority="Trachéophytes - Enjeu 2 Massif Central" to taxons'
INSERT INTO taxonomie.cor_taxon_attribut (
    id_attribut,
    valeur_attribut,
    cd_ref
)
    SELECT DISTINCT
        taxonomie.get_id_attribut_by_name('forest_flora_priority'),
        'Trachéophytes - Enjeu 2 Massif Central',
        t.cd_ref
    FROM taxonomie.taxref AS t
    WHERE t.cd_nom IN (
        SELECT cd_nom
        FROM gn_imports.piority_forest_flora
        WHERE "group" = 'Tracheophyta'
            AND level_2_mc = TRUE
    )
ON CONFLICT (id_attribut, cd_ref) DO UPDATE
SET valeur_attribut = CONCAT_WS(
    '&',
    taxonomie.cor_taxon_attribut.valeur_attribut,
    EXCLUDED.valeur_attribut
) ;


\echo '----------------------------------------------------------------------------'
\echo 'Associate TaxHub attribut forest_flora_priority="Bryophytes - Alpes" to taxons'
INSERT INTO taxonomie.cor_taxon_attribut (
    id_attribut,
    valeur_attribut,
    cd_ref
)
    SELECT DISTINCT
        taxonomie.get_id_attribut_by_name('forest_flora_priority'),
        'Bryophytes - Alpes',
        t.cd_ref
    FROM taxonomie.taxref AS t
    WHERE t.cd_nom IN (
        SELECT cd_nom
        FROM gn_imports.piority_forest_flora
        WHERE "group" = 'Bryophyta'
            AND level_1_alp = TRUE
    )
ON CONFLICT (id_attribut, cd_ref) DO UPDATE
SET valeur_attribut = CONCAT_WS(
    '&',
    taxonomie.cor_taxon_attribut.valeur_attribut,
    EXCLUDED.valeur_attribut
) ;


\echo '----------------------------------------------------------------------------'
\echo 'Associate TaxHub attribut forest_flora_priority="Bryophytes - Massif Central" to taxons'
INSERT INTO taxonomie.cor_taxon_attribut (
    id_attribut,
    valeur_attribut,
    cd_ref
)
    SELECT DISTINCT
        taxonomie.get_id_attribut_by_name('forest_flora_priority'),
        'Bryophytes - Massif Central',
        t.cd_ref
    FROM taxonomie.taxref AS t
    WHERE t.cd_nom IN (
        SELECT cd_nom
        FROM gn_imports.piority_forest_flora
        WHERE "group" = 'Bryophyta'
            AND level_1_mc = TRUE
    )
ON CONFLICT (id_attribut, cd_ref) DO UPDATE
SET valeur_attribut = CONCAT_WS(
    '&',
    taxonomie.cor_taxon_attribut.valeur_attribut,
    EXCLUDED.valeur_attribut
) ;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is OK:'
COMMIT ;
