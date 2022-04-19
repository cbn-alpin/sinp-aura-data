BEGIN;
-- This file contain a variable "${themeImportTable}"" which must be replaced
-- with "sed" before passing the updated content to psql.

\echo '-------------------------------------------------------------------------------'
\echo 'Upsert imported themes'
\echo 'Rights: db-owner'
\echo 'GeoNature database compatibility : v2.4.1+'

SET client_encoding = 'UTF8';


\echo '-------------------------------------------------------------------------------'
\echo 'Batch insertion in "bib_themes" of the imported themes'

DO $$
DECLARE
    step INTEGER ;
    stopAt INTEGER ;
    offsetCnt INTEGER := 0 ;
    affectedRows INTEGER;
BEGIN
    -- Set dynamicly stopAt and step
    stopAt := (SELECT COUNT(*) FROM gn_imports.${themeImportTable});
    step := gn_imports.computeImportStep(stopAt) ;
    RAISE NOTICE 'Total found: %, step used: %', stopAt, step ;

    RAISE NOTICE 'Start to loop on data to upsert in "bib_themes" table' ;
    WHILE offsetCnt < stopAt LOOP

        RAISE NOTICE '-------------------------------------------------' ;
        RAISE NOTICE 'Try to upsert % themes from %', step, offsetCnt ;

        INSERT INTO taxonomie.bib_themes (
            nom_theme,
            desc_theme,
            ordre,
            id_droit
        )
            SELECT
                tit.code AS nom_theme,
                tit.description AS desc_theme,
                (SELECT MAX(bt.ordre) + 1 FROM taxonomie.bib_themes AS bt WHERE bt.nom_theme != tit.code) AS ordre,
                4 AS id_droit
            FROM gn_imports.${themeImportTable} AS tit
            ORDER BY tit.gid ASC
            OFFSET offsetCnt
            LIMIT step
        ON CONFLICT (nom_theme) DO
            UPDATE SET
                desc_theme = EXCLUDED.desc_theme,
                ordre = EXCLUDED.ordre,
                id_droit = EXCLUDED.id_droit ;

        GET DIAGNOSTICS affectedRows = ROW_COUNT;
        RAISE NOTICE 'Upsert affected rows: %', affectedRows ;

        offsetCnt := offsetCnt + (step) ;
    END LOOP ;
END
$$ ;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
