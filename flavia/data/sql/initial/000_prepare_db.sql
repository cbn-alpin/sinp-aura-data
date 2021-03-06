BEGIN;


\echo '-------------------------------------------------------------------------------'
\echo 'Insert missing data in GeoNature DB'
\echo 'GeoNature database compatibility : v2.6.1'

SET client_encoding = 'UTF8';

\echo '-------------------------------------------------------------------------------'
\echo 'Insert missing OLD_1 value of DATA_TYP nomenclature'
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
        ref_nomenclatures.get_id_nomenclature_type('DATA_TYP'),
        'OLD_1',
        'NR',
        'NR',
        'Le type de JDD n''est pas renseigné',
        'NR',
        'Le type de JDD n''est pas renseigné',
        'SINP',
        'Gelé',
        0,
        '103.006',
        true
    WHERE NOT EXISTS(
        SELECT 'X'
        FROM ref_nomenclatures.t_nomenclatures AS tn
        WHERE tn.id_type = ref_nomenclatures.get_id_nomenclature_type('DATA_TYP')
            AND tn.cd_nomenclature = 'OLD_1'
    ) ;


\echo '-------------------------------------------------------------------------------'
\echo 'Insert missing OLD_2 value of DATA_TYP nomenclature'
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
        ref_nomenclatures.get_id_nomenclature_type('DATA_TYP'),
        'OLD_2',
        'Hab',
        'Hab',
        'Habitats',
        'Hab',
        'Habitats',
        'SINP',
        'Gelé',
        0,
        '103.007',
        true
    WHERE NOT EXISTS(
        SELECT 'X'
        FROM ref_nomenclatures.t_nomenclatures AS tn
        WHERE tn.id_type = ref_nomenclatures.get_id_nomenclature_type('DATA_TYP')
            AND tn.cd_nomenclature = 'OLD_2'
    ) ;


\echo '-------------------------------------------------------------------------------'
\echo 'Insert missing OLD_3 value of DATA_TYP nomenclature'
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
        ref_nomenclatures.get_id_nomenclature_type('DATA_TYP'),
        'OLD_3',
        'Tax',
        'Tax',
        'Taxons',
        'Tax',
        'Taxons',
        'SINP',
        'Gelé',
        0,
        '103.008',
        true
    WHERE NOT EXISTS(
        SELECT 'X'
        FROM ref_nomenclatures.t_nomenclatures AS tn
        WHERE tn.id_type = ref_nomenclatures.get_id_nomenclature_type('DATA_TYP')
            AND tn.cd_nomenclature = 'OLD_3'
    ) ;

\echo '-------------------------------------------------------------------------------'
\echo 'Insert missing DS_PUBLIQUE nomenclatures'
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
        ref_nomenclatures.get_id_nomenclature_type('DS_PUBLIQUE'),
        'Re',
        'Publique Régie',
        'Publique régie',
        'Publique régie : La Donnée Source est publique et a été produite directement par un organisme ayant autorité publique avec ses moyens humains et techniques propres.',
        'Publique régie',
        'Publique régie : La Donnée Source est publique et a été produite directement par un organisme ayant autorité publique avec ses moyens humains et techniques propres.',
        'SINP',
        'Gelé',
        0,
        '002.003',
        true
    WHERE NOT EXISTS(
        SELECT 'X'
        FROM ref_nomenclatures.t_nomenclatures AS tn
        WHERE tn.id_type = ref_nomenclatures.get_id_nomenclature_type('DS_PUBLIQUE')
            AND tn.cd_nomenclature = 'Re'
    ) ;
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
        ref_nomenclatures.get_id_nomenclature_type('DS_PUBLIQUE'),
        'Ac',
        'Publique acquise',
        'Publique acquise',
        'Publique Acquise : La donnée-source a été produite par un organisme privé (associations, bureaux d’étude…) ou une personne physique à titre personnel. Les droits patrimoniaux exclusifs ou non exclusifs, de copie, traitement et diffusion sans limitation ont été acquis à titre gracieux ou payant, sur marché ou par convention, par un organisme ayant autorité publique. La donnée-source est devenue publique.',
        'Publique acquise',
        'Publique Acquise : La donnée-source a été produite par un organisme privé (associations, bureaux d’étude…) ou une personne physique à titre personnel. Les droits patrimoniaux exclusifs ou non exclusifs, de copie, traitement et diffusion sans limitation ont été acquis à titre gracieux ou payant, sur marché ou par convention, par un organisme ayant autorité publique. La donnée-source est devenue publique.',
        'SINP',
        'Gelé',
        0,
        '002.004',
        true
    WHERE NOT EXISTS(
        SELECT 'X'
        FROM ref_nomenclatures.t_nomenclatures AS tn
        WHERE tn.id_type = ref_nomenclatures.get_id_nomenclature_type('DS_PUBLIQUE')
            AND tn.cd_nomenclature = 'Ac'
    ) ;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
