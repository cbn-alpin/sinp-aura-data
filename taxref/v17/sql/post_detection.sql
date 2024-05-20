-- Mise à jour TaxRef v16 vers v17 pour le SINP AURA

-- Enable foreign keys constraints
ALTER TABLE taxonomie.t_medias ADD CONSTRAINT check_is_cd_ref CHECK (cd_ref = taxonomie.find_cdref(cd_ref)) ;

-- Enable trigger "tri_meta_dates_change_synthese"
ALTER TABLE gn_synthese.synthese ENABLE TRIGGER tri_meta_dates_change_synthese ;

-- Enable trigger "tri_update_calculate_sensitivity"
ALTER TABLE gn_synthese.synthese ENABLE TRIGGER tri_update_calculate_sensitivity ;

-- Update TaxRef version in t_parameters
UPDATE gn_commons.t_parameters
SET parameter_value = 'Taxref V17.0'
WHERE parameter_name = 'taxref_version' ;
