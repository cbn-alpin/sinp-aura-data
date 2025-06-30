BEGIN;

-- Réactivation des triggers sur la synthese
ALTER TABLE gn_synthese.synthese ENABLE TRIGGER tri_meta_dates_change_synthese;
ALTER TABLE gn_synthese.synthese ENABLE TRIGGER tri_update_calculate_sensitivity;

-- Rétablissement de la contrainte FK sur cd_nom de gn_synthese.synthese
ALTER TABLE gn_synthese.synthese
    ADD CONSTRAINT fk_synthese_cd_nom
    FOREIGN KEY (cd_nom) REFERENCES taxonomie.taxref(cd_nom);

-- Rétablissement de la contrainte FK sur cd_nom de taxonomie.bib_noms
ALTER TABLE taxonomie.bib_noms
    ADD CONSTRAINT fk_bib_nom_taxref
    FOREIGN KEY (cd_nom) REFERENCES taxonomie.taxref(cd_nom);

-- Rétablissement de la contrainte FK sur cd_ref de taxonomie.t_medias
ALTER TABLE taxonomie.t_medias
    ADD CONSTRAINT fk_t_media_bib_noms
    FOREIGN KEY (cd_ref) REFERENCES taxonomie.bib_noms(cd_nom);

-- (Optionnel) Rétablissement de la contrainte CHECK si elle existait avant
-- ALTER TABLE taxonomie.t_medias ADD CONSTRAINT check_is_cd_ref CHECK (cd_ref > 0);

COMMIT;
