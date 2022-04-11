-- Mise à jour TaxRef v14 vers v15 pour le SINP PACA
BEGIN;

-- Enable check constraint on cd_nom
ALTER TABLE gn_synthese.synthese ADD CONSTRAINT fk_synthese_cd_nom
    FOREIGN KEY (cd_nom) REFERENCES taxonomie.taxref(cd_nom)
    ON UPDATE CASCADE ;

-- Enable trigger "tri_meta_dates_change_synthese"
ALTER TABLE gn_synthese.synthese ENABLE TRIGGER tri_meta_dates_change_synthese ;

-- Enable trigger "tri_update_calculate_sensitivity"
ALTER TABLE gn_synthese.synthese ENABLE TRIGGER tri_update_calculate_sensitivity ;

-- Update parameter TaxRef version
UPDATE gn_commons.t_parameters
SET parameter_value = 'Taxref V15.0'
WHERE parameter_name = 'taxref_version' ;

-- Commit if all good
COMMIT;
