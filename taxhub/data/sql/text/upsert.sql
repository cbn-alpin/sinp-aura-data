BEGIN;
-- This file contain a variable "${textImportTable}" which must be replaced
-- with "sed" before passing the updated content to psql.

\echo '-------------------------------------------------------------------------------'
\echo 'Upsert imported attributs-taxons-values'
\echo 'Rights: db-owner'
\echo 'GeoNature database compatibility : v2.4.1+'

SET client_encoding = 'UTF8';


\echo '-------------------------------------------------------------------------------'
\echo 'Batch insertion in "cor_taxon_attribut" of the imported attributs-taxons-values'

DO $$
DECLARE
    step INTEGER ;
    stopAt INTEGER ;
    offsetCnt INTEGER := 0 ;
    affectedRows INTEGER;
BEGIN
    -- Set dynamicly stopAt and step
    stopAt := (SELECT COUNT(*) FROM gn_imports.${textImportTable});
    step := gn_imports.computeImportStep(stopAt) ;
    RAISE NOTICE 'Total found: %, step used: %', stopAt, step ;

    RAISE NOTICE 'Start to loop on data to upsert in "cor_taxon_attribut" table' ;
    WHILE offsetCnt < stopAt LOOP

        RAISE NOTICE '-------------------------------------------------' ;
        RAISE NOTICE 'Try to upsert % attributs-taxons-values from %', step, offsetCnt ;

        INSERT INTO taxonomie.cor_taxon_attribut (
            cd_ref,
            id_attribut,
            valeur_attribut
        )
            SELECT
                tit.cd_ref,
                tit.id_attribut,
                tit."value" AS valeur_attribut
            FROM gn_imports.${textImportTable} AS tit
            ORDER BY tit.gid ASC
            OFFSET offsetCnt
            LIMIT step
        ON CONFLICT ON CONSTRAINT cor_taxon_attribut_pkey DO
            UPDATE SET valeur_attribut = EXCLUDED.valeur_attribut ;

        GET DIAGNOSTICS affectedRows = ROW_COUNT;
        RAISE NOTICE 'Upsert affected rows: %', affectedRows ;

        offsetCnt := offsetCnt + (step) ;
    END LOOP ;
END
$$ ;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
