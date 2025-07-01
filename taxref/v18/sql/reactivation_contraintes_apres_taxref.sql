BEGIN;

-- Réactivation des triggers sur la synthese
ALTER TABLE gn_synthese.synthese ENABLE TRIGGER tri_meta_dates_change_synthese;
ALTER TABLE gn_synthese.synthese ENABLE TRIGGER tri_update_calculate_sensitivity;

-- Ajout des contraintes (remplacement)
ALTER TABLE gn_synthese.synthese ADD CONSTRAINT fk_synthese_cd_nom FOREIGN KEY (cd_nom) REFERENCES taxonomie.taxref(cd_nom) ON UPDATE CASCADE;
ALTER TABLE taxonomie.t_medias ADD CONSTRAINT fk_t_media_bib_noms FOREIGN KEY (cd_ref) REFERENCES taxonomie.bib_noms(cd_nom) MATCH FULL ON UPDATE CASCADE;
ALTER TABLE taxonomie.t_medias ADD CONSTRAINT check_is_cd_ref CHECK ((cd_ref = taxonomie.find_cdref(cd_ref)));
ALTER TABLE taxonomie.bib_noms ADD CONSTRAINT fk_bib_nom_taxref FOREIGN KEY (cd_nom) REFERENCES taxonomie.taxref(cd_nom);
ALTER TABLE taxonomie.bib_noms ADD CONSTRAINT bib_noms_cd_nom_key UNIQUE (cd_nom);

COMMIT;