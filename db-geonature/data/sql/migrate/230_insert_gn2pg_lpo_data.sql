-- Script to trigger Gn2PG LPO data insert to destination DB

\echo '-------------------------------------------------------------------------------'
\echo 'Batch insertion of the LPO metadata in gn_meta with the Gn2Pg trigger'

DO $$
DECLARE
    step INTEGER := 500 ;
    total INTEGER ;
    startTime TIMESTAMP ;
    i INTEGER := 0;
    id_record RECORD ;
    curs_data CURSOR FOR
        SELECT m.uuid
        FROM gn2pg_lpo.metadata_json  AS m
        WHERE m.source = 'lpo'
        --  AND d.unique_id_sinp NOT IN (
        --    SELECT DISTINCT uuid
        --    FROM gn2pg_lpo.error_log
        --    WHERE source = 'lpo' AND controler = 'metadata'
        --  )
        ORDER BY m.uuid ;
BEGIN
    SELECT COUNT(*) INTO total FROM gn2pg_lpo.metadata_json ;
    RAISE NOTICE 'Total found: %, step used: %', total, step ;

    RAISE NOTICE '-------------------------------------------------' ;
    RAISE NOTICE 'Start to loop on LPO metadata to trigger insert in "gn_meta" schema' ;
    FOR id_record IN curs_data LOOP
        i := i + 1;

        UPDATE gn2pg_lpo.metadata_json
        SET uuid = uuid
        WHERE source = 'lpo' AND uuid = id_record.uuid ;

        IF i % step = 0 OR i = 1 THEN
            IF i % step = 0 THEN
                RAISE NOTICE 'Processed record % / %', i, total;
                RAISE NOTICE 'Loop execution time: %', clock_timestamp() - startTime;
            END IF;
            startTime := clock_timestamp();
            RAISE NOTICE '-------------------------------------------------';
            RAISE NOTICE 'Triggering % LPO metadata from %', step, i ;
        END IF;
    END LOOP;
END
$$ ;


\echo '-------------------------------------------------------------------------------'
\echo 'Disable triggers on Synthese'

\echo 'Disable trigger "tri_insert_calculate_sensitivity"'
ALTER TABLE gn_synthese.synthese DISABLE TRIGGER tri_insert_calculate_sensitivity ;

\echo 'Disable trigger "tri_update_calculate_sensitivity"'
ALTER TABLE gn_synthese.synthese DISABLE TRIGGER tri_update_calculate_sensitivity ;


\echo 'Disable trigger "tri_insert_cor_area_synthese"'
ALTER TABLE gn_synthese.synthese DISABLE TRIGGER tri_insert_cor_area_synthese ;

\echo 'Disable trigger "tri_update_cor_area_synthese"'
ALTER TABLE gn_synthese.synthese DISABLE TRIGGER tri_update_cor_area_synthese ;


\echo '-------------------------------------------------------------------------------'
\echo 'Batch direct insertion of the LPO data in Synthese'

DO $$
DECLARE
    step INTEGER := 2000000 ;
    stopAt INTEGER ;
    offsetCnt INTEGER := 0 ;
    last_id_data INT := 0 ;
    affectedRows INTEGER := 1 ;
    insertedRows INTEGER ;
    loopStartTime TIMESTAMP ;
    totalRead INTEGER := 0 ;         -- Statistiques globales
    totalInserted INTEGER := 0 ;     -- Statistiques globales
    globalStartTime TIMESTAMP := clock_timestamp() ;
BEGIN
    -- Set dynamicly stopAt
    SELECT COUNT(*) INTO stopAt
    FROM gn2pg_lpo.data_json ;

    RAISE NOTICE 'Total found: %, step used: %', stopAt, step ;

    RAISE NOTICE 'Start to loop on LPO data to insert in "gn_synthese.synthese" table' ;
    WHILE affectedRows > 0 LOOP

        RAISE NOTICE '-------------------------------------------------' ;
        RAISE NOTICE 'Inserting % LPO data from %', step, offsetCnt ;

        loopStartTime := clock_timestamp();

        WITH gn2pg_data AS (
            SELECT
                id_data,
                source,
                uuid,
                item
            FROM gn2pg_lpo.data_json
            WHERE id_data > last_id_data
            ORDER BY id_data ASC
            LIMIT step
        ),
        computed_gn2pg_data AS (
            SELECT
                source,
                uuid,
                item,
                st_setsrid(st_geomfromtext(item #>> '{wkt_4326}'), 4326) AS the_geom_4326,
                CASE
                    WHEN item ? 'area_attachment' AND (item ->> 'area_attachment') IS DISTINCT FROM 'null'
                        THEN ref_geo.get_id_area_by_code(
                            item #>> '{area_attachment,type_code}', item #>> '{area_attachment,area_code}'
                        )
                        ELSE NULL
                END AS id_area_attachment
            FROM gn2pg_data
        ),
        insert_step AS (
            INSERT INTO gn_synthese.synthese (
                unique_id_sinp,
                unique_id_sinp_grp,
                id_source,
                entity_source_pk_value,
                id_dataset,
                id_nomenclature_geo_object_nature,
                id_nomenclature_grp_typ,
                grp_method,
                id_nomenclature_obs_technique,
                id_nomenclature_bio_status,
                id_nomenclature_bio_condition,
                id_nomenclature_naturalness,
                id_nomenclature_exist_proof,
                id_nomenclature_valid_status,
                id_nomenclature_diffusion_level,
                id_nomenclature_life_stage,
                id_nomenclature_sex,
                id_nomenclature_obj_count,
                id_nomenclature_type_count,
                id_nomenclature_sensitivity,
                id_nomenclature_observation_status,
                id_nomenclature_blurring,
                id_nomenclature_source_status,
                id_nomenclature_info_geo_type,
                id_nomenclature_behaviour,
                id_nomenclature_biogeo_status,
                reference_biblio,
                count_min,
                count_max,
                cd_nom,
                cd_hab,
                nom_cite,
                meta_v_taxref,
                sample_number_proof,
                digital_proof,
                non_digital_proof,
                altitude_min,
                altitude_max,
                depth_min,
                depth_max,
                place_name,
                the_geom_4326,
                the_geom_point,
                the_geom_local,
                "precision",
                id_area_attachment,
                date_min,
                date_max,
                validator,
                validation_comment,
                observers,
                determiner,
                id_digitiser,
                id_nomenclature_determination_method,
                comment_context,
                comment_description,
                additional_data,
                meta_validation_date,
                last_action
            )
            SELECT
                uuid AS unique_id_sinp,
                CAST(item #>> '{id_perm_grp_sinp}' AS UUID) AS unique_id_sinp_grp,
                gn_synthese.get_id_source_by_name(source) AS id_source,
                item #>> '{id_synthese}' AS entity_source_pk_value,
                gn_meta.get_id_dataset_by_uuid(CAST(item #>> '{jdd_uuid}' AS UUID)) AS id_dataset,
                ref_nomenclatures.get_id_nomenclature('NAT_OBJ_GEO', item #>> '{nature_objet_geo}') AS id_nomenclature_geo_object_nature,
                ref_nomenclatures.get_id_nomenclature('TYP_GRP', item #>> '{type_regroupement}') AS id_nomenclature_grp_typ,
                item #>> '{methode_regroupement}' AS grp_method,
                ref_nomenclatures.get_id_nomenclature('METH_OBS', item #>> '{technique_obs}') AS id_nomenclature_obs_technique,
                ref_nomenclatures.get_id_nomenclature('STATUT_BIO', item #>> '{statut_biologique}') AS id_nomenclature_bio_status,
                ref_nomenclatures.get_id_nomenclature('ETA_BIO', item #>> '{etat_biologique}') AS id_nomenclature_bio_condition,
                ref_nomenclatures.get_id_nomenclature('NATURALITE', item #>> '{naturalite}') AS id_nomenclature_naturalness,
                ref_nomenclatures.get_id_nomenclature('PREUVE_EXIST', item #>> '{preuve_existante}') AS id_nomenclature_exist_proof,
                ref_nomenclatures.get_id_nomenclature('STATUT_VALID', item #>> '{statut_validation}') AS id_nomenclature_valid_status,
                ref_nomenclatures.get_id_nomenclature('NIV_PRECIS', item #>> '{precision_diffusion}') AS id_nomenclature_diffusion_level,
                ref_nomenclatures.get_id_nomenclature('STADE_VIE', item #>> '{stade_vie}') AS id_nomenclature_life_stage,
                ref_nomenclatures.get_id_nomenclature('SEXE', item #>> '{sexe}') AS id_nomenclature_sex,
                ref_nomenclatures.get_id_nomenclature('OBJ_DENBR', item #>> '{objet_denombrement}') AS id_nomenclature_obj_count,
                ref_nomenclatures.get_id_nomenclature('TYP_DENBR', item #>> '{type_denombrement}') AS id_nomenclature_type_count,
                ref_nomenclatures.get_id_nomenclature('SENSIBILITE', item #>> '{niveau_sensibilite}') AS id_nomenclature_sensitivity,
                ref_nomenclatures.get_id_nomenclature('STATUT_OBS', item #>> '{statut_observation}') AS id_nomenclature_observation_status,
                ref_nomenclatures.get_id_nomenclature('DEE_FLOU', item #>> '{floutage_dee}') AS id_nomenclature_blurring,
                ref_nomenclatures.get_id_nomenclature('STATUT_SOURCE', item #>> '{statut_source}') AS id_nomenclature_source_status,
                CASE
                    WHEN id_area_attachment IS NOT NULL
                        THEN ref_nomenclatures.get_id_nomenclature('TYP_INF_GEO', '2')
                        ELSE ref_nomenclatures.get_id_nomenclature('TYP_INF_GEO', '1')
                END AS id_nomenclature_info_geo_type,
                ref_nomenclatures.get_id_nomenclature('OCC_COMPORTEMENT', item #>> '{comportement}') AS id_nomenclature_behaviour,
                ref_nomenclatures.get_id_nomenclature('STAT_BIOGEO', item #>> '{statut_biogeo}') AS id_nomenclature_biogeo_status,
                item #>> '{reference_biblio}' AS reference_biblio,
                CAST(item #>> '{nombre_min}' AS INT) AS count_min,
                CAST(item #>> '{nombre_max}' AS INT) AS count_max,
                CAST(item #>> '{cd_nom}' AS INT) AS cd_nom,
                CAST(item #>> '{cd_hab}' AS INT) AS cd_hab,
                item #>> '{nom_cite}' AS nom_cite,
                item #>> '{version_taxref}' AS meta_v_taxref,
                item #>> '{numero_preuve}' AS sample_number_proof,
                item #>> '{preuve_numerique}' AS digital_proof,
                item #>> '{preuve_non_numerique}' AS non_digital_proof,
                CAST(item #>> '{altitude_min}' AS INT) AS altitude_min,
                CAST(item #>> '{altitude_max}' AS INT) AS altitude_max,
                CAST(item #>> '{profondeur_min}' AS INT) AS depth_min,
                CAST(item #>> '{profondeur_max}' AS INT) AS depth_max,
                item #>> '{nom_lieu}' AS place_name,
                the_geom_4326,
                st_centroid(the_geom_4326) AS the_geom_point,
                st_transform(the_geom_4326, (SELECT find_srid('gn_synthese', 'synthese', 'the_geom_local'))) AS the_geom_local,
                CAST(item #>> '{precision}' AS INT) AS "precision",
                id_area_attachment,
                CAST(item #>> '{date_debut}' AS TIMESTAMP) AS date_min,
                CAST(item #>> '{date_fin}' AS TIMESTAMP) AS date_max,
                item #>> '{validateur}' AS validator,
                item #>> '{comment_validation}' AS validation_comment,
                item #>> '{observateurs}' AS observers,
                item #>> '{determinateur}' AS determiner,
                NULL::INT AS id_digitiser,
                ref_nomenclatures.get_id_nomenclature('TYPE', item #>> '{label}') AS id_nomenclature_determination_method,
                item #>> '{comment_releve}' AS comment_context,
                item #>> '{comment_occurrence}' AS comment_description,
                item #> '{donnees_additionnelles}' AS additional_data,
                NULL::TIMESTAMP AS meta_validation_date,
                'I'::bpchar AS last_action
            FROM computed_gn2pg_data
            ON CONFLICT DO NOTHING
            RETURNING 1
        )
        SELECT
            COALESCE((SELECT MAX(id_data) FROM gn2pg_data), last_id_data),
            (SELECT COUNT(*) FROM gn2pg_data),
            (SELECT COUNT(*) FROM insert_step)
        INTO
            last_id_data,
            affectedRows,
            insertedRows ;

        totalRead := totalRead + affectedRows;
        totalInserted := totalInserted + insertedRows;

        RAISE NOTICE 'Lot read: % rows (Last id_data : %)', affectedRows, last_id_data ;
        RAISE NOTICE 'New inserted rows : % (Ignored duplicates : %)', insertedRows, (affectedRows - insertedRows);
        RAISE NOTICE 'Loop execution time: %', clock_timestamp() - loopStartTime;

        offsetCnt := offsetCnt + (step) ;
    END LOOP ;

    RAISE NOTICE '=================================================' ;
    RAISE NOTICE 'IMPORT DONE !' ;
    RAISE NOTICE 'Total number of lines read: %', totalRead ;
    RAISE NOTICE 'Total number of inserted lines: %', totalInserted ;
    RAISE NOTICE 'Total time : %', clock_timestamp() - globalStartTime ;
END
$$ ;


\echo '-------------------------------------------------------------------------------'
\echo 'Enable triggers on Synthese'

\echo 'Enable trigger "tri_insert_calculate_sensitivity"'
ALTER TABLE gn_synthese.synthese ENABLE TRIGGER tri_insert_calculate_sensitivity ;

\echo 'Enable trigger "tri_update_calculate_sensitivity"'
ALTER TABLE gn_synthese.synthese ENABLE TRIGGER tri_update_calculate_sensitivity ;


\echo 'Enable trigger "tri_insert_cor_area_synthese"'
ALTER TABLE gn_synthese.synthese ENABLE TRIGGER tri_insert_cor_area_synthese ;

\echo 'Enable trigger "tri_update_cor_area_synthese"'
ALTER TABLE gn_synthese.synthese ENABLE TRIGGER tri_update_cor_area_synthese ;
