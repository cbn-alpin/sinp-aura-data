-- Add values to "DS_PUBLIQUE" nomenclature

BEGIN ;


\echo '----------------------------------------------------------------------------'
\echo 'Insert new values to "DS_PUBLIQUE" nomenclature:'

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
VALUES
(
    ref_nomenclatures.get_id_nomenclature_type('DS_PUBLIQUE'),
    'Re',
    'Public Régie',
    'Public Régie',
    'Publique régie : La Donnée Source est publique et a été produite directement par un organisme ayant autorité publique avec ses moyens humains et techniques propres.',
    'Public Régie',
    'Publique régie : La Donnée Source est publique et a été produite directement par un organisme ayant autorité publique avec ses moyens humains et techniques propres.',
    'SINP',
    'Validé',
    0,
    lpad(ref_nomenclatures.get_id_nomenclature_type('DS_PUBLIQUE')::text, 3, '0')||'.'||'003',
    TRUE
),
(
    ref_nomenclatures.get_id_nomenclature_type('DS_PUBLIQUE'),
    'Re',
    'Publique acquise',
    'Publique acquise',
    'Publique Acquise : La donnée-source a été produite par un organisme privé (associations, bureaux d’étude…) ou une personne physique à titre personnel. Les droits patrimoniaux exclusifs ou non exclusifs, de copie, traitement et diffusion sans limitation ont été acquis à titre gracieux ou payant, sur marché ou par convention, par un organisme ayant autorité publique. La donnée-source est devenue publique.',
    'Publique acquise',
    'Publique Acquise : La donnée-source a été produite par un organisme privé (associations, bureaux d’étude…) ou une personne physique à titre personnel. Les droits patrimoniaux exclusifs ou non exclusifs, de copie, traitement et diffusion sans limitation ont été acquis à titre gracieux ou payant, sur marché ou par convention, par un organisme ayant autorité publique. La donnée-source est devenue publique.',
    'SINP',
    'Validé',
    0,
    lpad(ref_nomenclatures.get_id_nomenclature_type('DS_PUBLIQUE')::text, 3, '0')||'.'||'004',
    TRUE
)
ON CONFLICT DO NOTHING ;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is OK:'
COMMIT ;
