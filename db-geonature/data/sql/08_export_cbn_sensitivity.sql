-- Required rights: DB OWNER
-- GeoNature database compatibility : v2.6.0+
-- Export observations in synthese where sensitivity was fixed to level 2 for CBNs data.
-- Used list of 129 sensitive taxa of AURA.
BEGIN;


\echo '-------------------------------------------------------------------------------'
\echo 'Export fixed sensitivity data for CBNs to CSV file'
COPY (
    SELECT
        id_synthese,
        unique_id_sinp,
        entity_source_pk_value,
        cd_nom,
        nom_cite
    FROM gn_synthese.synthese
    WHERE id_source >= :idSourceMin AND id_source <= :idSourceMax
        AND cd_nom IN (
            SELECT t.cd_nom
            FROM taxonomie.taxref AS t
                JOIN taxonomie.taxref AS tr
                    ON t.cd_ref = tr.cd_ref
            WHERE tr.cd_nom IN (80955, 81355, 82493, 82498, 131373, 82509, 82535, 612395, 83638, 84476, 131826, 84497, 84554, 84738, 131929, 85628, 132135, 86085, 86122, 86182, 86186, 86189, 86199, 87102, 87417, 87620, 87897, 88077, 88404, 88467, 132676, 526279, 88561, 88562, 88576, 89195, 90046, 90180, 90389, 91132, 92807, 93456, 133766, 94599, 133791, 789978, 95561, 95601, 95864, 134101, 96101, 159904, 521629, 96695, 717179, 99214, 99521, 609224, 99763, 100024, 100273, 101223, 136639, 102794, 717776, 103056, 103383, 612499, 103501, 103862, 610647, 610656, 105204, 137229, 105687, 105908, 106446, 106517, 107013, 719047, 107024, 610911, 107122, 108044, 137826, 109095, 718725, 110068, 138235, 110296, 138241, 110306, 110473, 113243, 114035, 114080, 115302, 115395, 115563, 115883, 117090, 117139, 117820, 119812, 140615, 121076, 121184, 140852, 122112, 621123, 718781, 123872, 123960, 141546, 125895, 141545, 127915, 127921, 127928, 127943, 127945, 127950, 128291, 129275, 129596, 129643, 129660, 130128)
        )
        AND (
            id_nomenclature_sensitivity IS NULL
            OR id_nomenclature_sensitivity != ref_nomenclatures.get_id_nomenclature('SENSIBILITE', '2')
        )
)
TO :'csvFilePath' DELIMITER E'\t' CSV HEADER NULL '\N' ;


\echo '-------------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;