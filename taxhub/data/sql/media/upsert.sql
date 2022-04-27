BEGIN;
-- This file contain a variable "${mediaImportTable}" which must be replaced
-- with "sed" before passing the updated content to psql.

\echo '-------------------------------------------------------------------------------'
\echo 'Upsert imported media'
\echo 'Rights: db-owner'
\echo 'GeoNature database compatibility : v2.4.1+'

SET client_encoding = 'UTF8';


\echo '-------------------------------------------------------------------------------'
\echo 'Update bib_noms with cd_nom from synthese'
INSERT INTO taxonomie.bib_noms (cd_nom, cd_ref)
    SELECT DISTINCT s.cd_nom, t.cd_ref
    FROM gn_synthese.synthese AS s
        JOIN taxonomie.taxref AS t
            ON s.cd_nom = t.cd_nom
    WHERE NOT s.cd_nom IN (SELECT DISTINCT cd_nom FROM taxonomie.bib_noms);


\echo '-------------------------------------------------------------------------------'
\echo 'Drop then add constraint on "t_medias" for upsert'
ALTER TABLE taxonomie.t_medias DROP CONSTRAINT IF EXISTS uniq_idx_t_medias_url ;
ALTER TABLE taxonomie.t_medias ADD CONSTRAINT uniq_idx_t_medias_url UNIQUE ("url") ;


\echo '-------------------------------------------------------------------------------'
\echo 'Batch insertion in "t_medias" of the imported media'

DO $$
DECLARE
    step INTEGER ;
    stopAt INTEGER ;
    offsetCnt INTEGER := 0 ;
    affectedRows INTEGER;
BEGIN
    -- Set dynamicly stopAt and step
    stopAt := (SELECT COUNT(*) FROM gn_imports.${mediaImportTable});
    step := gn_imports.computeImportStep(stopAt) ;
    RAISE NOTICE 'Total found: %, step used: %', stopAt, step ;

    RAISE NOTICE 'Start to loop on data to upsert in "t_medias" table' ;
    WHILE offsetCnt < stopAt LOOP

        RAISE NOTICE '-------------------------------------------------' ;
        RAISE NOTICE 'Try to upsert % media from %', step, offsetCnt ;

        INSERT INTO taxonomie.t_medias (
            cd_ref,
            titre,
            "url",
            chemin,
            auteur,
            desc_media,
            date_media,
            id_type,
            source,
            licence
        )
            SELECT DISTINCT ON (mit."url")
                mit.cd_ref,
                mit.title,
                mit."url",
                mit."path",
                mit.author,
                mit."description",
                mit."date",
                2,
                mit.source,
                mit.licence
            FROM gn_imports.${mediaImportTable} AS mit
                JOIN taxonomie.bib_noms AS bn
                    ON mit.cd_ref = bn.cd_nom
            ORDER BY mit."url" ASC
            OFFSET offsetCnt
            LIMIT step
        ON CONFLICT ("url") DO
            UPDATE SET
                cd_ref = EXCLUDED.cd_ref,
                titre =  EXCLUDED.titre,
                auteur = EXCLUDED.auteur,
                desc_media = EXCLUDED.desc_media,
                date_media = EXCLUDED.date_media,
                id_type = EXCLUDED.id_type,
                source = EXCLUDED.source,
                licence = EXCLUDED.licence ;

        GET DIAGNOSTICS affectedRows = ROW_COUNT;
        RAISE NOTICE 'Upsert affected rows: %', affectedRows ;

        offsetCnt := offsetCnt + (step) ;
    END LOOP ;
END
$$ ;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
