-- Script to clean nomenclatures set to NULL in t_acquisition_frameworks

BEGIN;


\echo '----------------------------------------------------------------------------'
\echo 'Set financing type to "Mixte" when is NULL'

UPDATE gn_meta.t_acquisition_frameworks AS af SET
    id_nomenclature_financing_type = ref_nomenclatures.get_id_nomenclature('TYPE_FINANCEMENT', '3')
WHERE af.id_nomenclature_financing_type IS NULL ;


\echo '----------------------------------------------------------------------------'
\echo 'Set territorial_level to "Régional terrestre, ou sous-région marine" when is NULL'

UPDATE gn_meta.t_acquisition_frameworks AS af SET
    id_nomenclature_territorial_level = ref_nomenclatures.get_id_nomenclature('NIVEAU_TERRITORIAL', '5')
WHERE af.id_nomenclature_territorial_level IS NULL ;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is OK:'
COMMIT;
