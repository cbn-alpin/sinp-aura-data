-- Script to create view of the Synthese for the Atlas.
-- For performances is better to use:
-- - a view insteaf of a materialized view
-- - function calls instead of subrequest
-- - only the fields used by Atlas materialized view

CREATE OR REPLACE VIEW gn_synthese.synthese_atlas AS
    SELECT
        id_synthese,
        the_geom_point,
        id_nomenclature_sensitivity,
        id_nomenclature_observation_status,
        cd_nom,
        date_min,
        altitude_min,
        altitude_max,
        observers,
        id_dataset
    FROM gn_synthese.synthese
    WHERE the_geom_point IS NOT NULL
        AND id_nomenclature_valid_status IN (
            ref_nomenclatures.get_id_nomenclature('STATUT_VALID', '0'),
            ref_nomenclatures.get_id_nomenclature('STATUT_VALID', '1'),
            ref_nomenclatures.get_id_nomenclature('STATUT_VALID', '2')
        )
        OR id_nomenclature_valid_status IS NULL ;
