BEGIN;


\echo '-------------------------------------------------------------------------------'
\echo 'Insert missing data in GeoNature DB'
\echo 'GeoNature database compatibility : v2.6.1'

SET client_encoding = 'UTF8';

\echo '-------------------------------------------------------------------------------'
\echo 'Insert missing STATUT_BIO nomenclatures'
INSERT INTO ref_nomenclatures.t_nomenclatures (
    id_type,
    cd_nomenclature,
    mnemonique,
    label_default,
    definition_default,
    label_fr,
    definition_fr,
    "source",
    statut,
    id_broader,
    "hierarchy",
    active
)
    SELECT
        ref_nomenclatures.get_id_nomenclature_type('STATUT_BIO'),
        '10',
        'Passage en vol',
        'Passage en vol',
        'Passage en vol : Indique que l''individu est de passage et en vol.',
        'Passage en vol',
        'Passage en vol : Indique que l''individu est de passage et en vol.',
        'SINP',
        'Gelé',
        0,
        '013.010',
        true
    WHERE NOT EXISTS(
        SELECT 'X'
        FROM ref_nomenclatures.t_nomenclatures AS tn
        WHERE tn.id_type = ref_nomenclatures.get_id_nomenclature_type('STATUT_BIO')
            AND tn.cd_nomenclature = '10'
    ) ;

\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
