-- Mise à jour TaxRef v13 vers v14 pour le SINP AURA
BEGIN;

-- Drop constraint on "cd_nom" field of  "synthese" table because we update cd_nom not yet in "taxref" table.
ALTER TABLE gn_synthese.synthese DROP CONSTRAINT IF EXISTS fk_synthese_cd_nom;

-- Set cd_nom to NULL for "cd_nom" with NO replacement "cd_nom" in "gn_synthese.synthese"
-- Data provider may wish to update these records.
UPDATE gn_synthese.synthese
SET cd_nom = NULL
WHERE cd_nom IN (101747) ;
--Number of row updated by cd_nom : ?

UPDATE gn_synthese.synthese
SET cd_nom = 29492
WHERE cd_nom = 29364 ;
--Number of row updated by cd_nom : ?

-- Deleting row from "cor_nom_liste"
DELETE FROM taxonomie.cor_nom_liste AS l
WHERE l.id_nom IN (
    SELECT id_nom
    FROM taxonomie.bib_noms
    WHERE cd_nom IN (101747)
) ;

-- Deleting row with problems solved in "taxonomie.bib_noms"
DELETE FROM taxonomie.bib_noms
WHERE cd_nom IN (101747) ;

-- Commit if all good
COMMIT;
