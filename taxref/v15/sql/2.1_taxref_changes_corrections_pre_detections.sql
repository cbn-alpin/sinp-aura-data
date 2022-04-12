-- Mise à jour TaxRef v14 vers v15 pour le SINP AURA
BEGIN;

-- Drop constraint on "cd_nom" field of  "synthese" table because we update cd_nom not yet in "taxref" table.
ALTER TABLE gn_synthese.synthese DROP CONSTRAINT IF EXISTS fk_synthese_cd_nom;

-- Disable trigger "tri_meta_dates_change_synthese"
ALTER TABLE gn_synthese.synthese DISABLE TRIGGER tri_meta_dates_change_synthese ;

-- Disable trigger "tri_update_calculate_sensitivity"
ALTER TABLE gn_synthese.synthese DISABLE TRIGGER tri_update_calculate_sensitivity ;

-- Set cd_nom to NULL for removing TaxRef cd_nom
UPDATE gn_synthese.synthese
SET cd_nom = NULL
WHERE cd_nom IN (125493, 810958);
--Number of row updated by cd_nom :

-- Update rows with replacement cd_nom in synthese:
UPDATE gn_synthese.synthese
SET cd_nom = 659518
WHERE cd_nom = 59457 ;
--Number of row updated by cd_nom : ?

-- Deleting rows in "cor_nom_liste" for:
-- - cd_nom with no replacement: 125493, 810958
-- - cd_nom with replacement already existing in bib_noms: 59457, 57226, 58440
DELETE FROM taxonomie.cor_nom_liste AS l
WHERE l.id_nom IN (
    SELECT id_nom
    FROM taxonomie.bib_noms
    WHERE cd_nom IN (125493, 810958, 59457, 57226, 58440)
) ;

-- Deleting rows in "taxonomie.bib_noms" for:
-- - cd_nom with no replacement: 125493, 810958
-- - cd_nom with replacement already existing in bib_noms: 59457, 57226, 58440
DELETE FROM taxonomie.bib_noms
WHERE cd_nom IN (125493, 810958, 59457, 57226, 58440) ;

-- Commit if all good
COMMIT;
