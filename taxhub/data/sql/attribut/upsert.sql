BEGIN;
-- This file contain a variable "${attributImportTable}" which must be replaced
-- with "sed" before passing the updated content to psql.

\echo '-------------------------------------------------------------------------------'
\echo 'Upsert imported attributs'
\echo 'Rights: db-owner'
\echo 'GeoNature database compatibility : v2.4.1+'

SET client_encoding = 'UTF8';


\echo '-------------------------------------------------------------------------------'
\echo 'Batch insertion in "bib_attributs" of the imported attributs'

DO $$
DECLARE
    step INTEGER ;
    stopAt INTEGER ;
    offsetCnt INTEGER := 0 ;
    affectedRows INTEGER;
BEGIN
    -- Set dynamicly stopAt and step
    stopAt := (SELECT COUNT(*) FROM gn_imports.${attributImportTable});
    step := gn_imports.computeImportStep(stopAt) ;
    RAISE NOTICE 'Total found: %, step used: %', stopAt, step ;

    RAISE NOTICE 'Start to loop on data to upsert in "bib_attributs" table' ;
    WHILE offsetCnt < stopAt LOOP

        RAISE NOTICE '-------------------------------------------------' ;
        RAISE NOTICE 'Try to upsert % attributes from %', step, offsetCnt ;

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
        )
            SELECT
                ait.code AS nom_attribut,
                ait.label AS label_attribut,
                COALESCE(NULLIF(ait."values", ''), '{}') AS liste_valeur_attribut,
                ait.mandatory AS obligatoire,
                ait."description" AS desc_attribut,
                ait."type" AS type_attribut,
                ait.widget AS type_widget,
                ait.theme_code AS id_theme,
                ait.order AS ordre
            FROM gn_imports.${attributImportTable} AS ait
            ORDER BY ait.gid ASC
            OFFSET offsetCnt
            LIMIT step
        ON CONFLICT (nom_attribut) DO
            UPDATE SET
                label_attribut = EXCLUDED.label_attribut,
                liste_valeur_attribut = COALESCE(NULLIF(EXCLUDED.liste_valeur_attribut, ''), '{}'),
                obligatoire = EXCLUDED.obligatoire,
                desc_attribut = EXCLUDED.desc_attribut,
                type_attribut = EXCLUDED.type_attribut,
                type_widget = EXCLUDED.type_widget,
                id_theme = EXCLUDED.id_theme,
                ordre = EXCLUDED.ordre ;

        GET DIAGNOSTICS affectedRows = ROW_COUNT;
        RAISE NOTICE 'Upsert affected rows: %', affectedRows ;

        offsetCnt := offsetCnt + (step) ;
    END LOOP ;
END
$$ ;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
