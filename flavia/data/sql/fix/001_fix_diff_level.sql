-- Required rights: DB OWNER
-- GeoNature database compatibility : v2.6.0+
-- Fix diffusion level code for Flavia observations.
BEGIN;


\echo '-------------------------------------------------------------------------------'
\echo 'Update diffusion_level in synthese for Flavia data'
UPDATE gn_synthese.synthese
SET id_nomenclature_diffusion_level = ref_nomenclatures.get_id_nomenclature('NIV_PRECIS', '2')
WHERE id_source >= :idSourceMin AND id_source <= :idSourceMax
    AND (
        id_nomenclature_diffusion_level IS NULL
        OR id_nomenclature_diffusion_level = ref_nomenclatures.get_id_nomenclature('NIV_PRECIS', '5')
    ) ;


\echo '-------------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
