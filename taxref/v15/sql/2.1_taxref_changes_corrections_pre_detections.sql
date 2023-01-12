-- Mise à jour TaxRef v14 vers v15 pour le SINP AURA
BEGIN;

-- Drop constraint on "cd_nom" field of  "synthese" table because we update cd_nom not yet in "taxref" table.
ALTER TABLE gn_synthese.synthese DROP CONSTRAINT IF EXISTS fk_synthese_cd_nom;

-- Disable trigger "tri_meta_dates_change_synthese"
ALTER TABLE gn_synthese.synthese DISABLE TRIGGER tri_meta_dates_change_synthese ;

-- Disable trigger "tri_update_calculate_sensitivity"
ALTER TABLE gn_synthese.synthese DISABLE TRIGGER tri_update_calculate_sensitivity ;

-- Set cd_nom to NULL for removing TaxRef cd_nom (cd_raison_suppression = 2 or 3)
UPDATE gn_synthese.synthese
SET cd_nom = NULL
WHERE cd_nom IN (124358, 125493, 131349, 134390, 312081, 717144, 810958, 811202);

-- Update rows with replacement cd_nom in synthese:
UPDATE gn_synthese.synthese SET cd_nom = 45589 WHERE cd_nom = 55448 ;
UPDATE gn_synthese.synthese SET cd_nom = 659518 WHERE cd_nom = 59457 ;
UPDATE gn_synthese.synthese SET cd_nom = 618756 WHERE cd_nom = 82371 ;
UPDATE gn_synthese.synthese SET cd_nom = 447838 WHERE cd_nom = 110314 ;


-- Deleting rows in "cor_nom_liste" for:
-- - cd_nom with no replacement: 125493, 810958
-- - cd_nom with replacement already existing in bib_noms: 59457, 57226, 58440
DELETE FROM taxonomie.cor_nom_liste AS l
WHERE l.id_nom IN (
    SELECT id_nom
    FROM taxonomie.bib_noms
    WHERE cd_nom IN (
        57226,
        58440,
        59457,
        82371,
        110314,
        124358,
        125493,
        134390,
        653233,
        660311,
        810958,
        811202
    )
) ;

-- Deleting rows in "taxonomie.bib_noms" for all kinds of conflicts.
-- "taxonomie.bib_noms" is only used in SINP for Taxhub INPN medias dowload script.
-- "taxonomie.bib_noms" must be recreated from gn_synthese.synthese if necessary.
DELETE FROM taxonomie.bib_noms
WHERE cd_nom IN (
    57226,
    58440,
    59457,
    82371,
    110314,
    124358,
    125493,
    134390,
    653233,
    660311,
    810958,
    811202
) ;


-- Remove useless attributs
DELETE FROM taxonomie.cor_taxon_attribut WHERE cd_ref IN (
    81992, -- Amaranthus hybridus (texte à garder => taxon supprimé)
    84230, -- Asarum europaeum (texte à garder => taxon supprimé)
    94693, -- Dianthus armeria (texte à garder => taxon supprimé)
    148559, -- Medicago minima (texte à garder => taxon maintenu)
    108703, -- Moenchia erecta (texte à garder => taxon supprimé)
    140428, -- Sagina saginoides (texte à garder => taxon maintenu)
    140485, -- Salix triandra (texte à garder => taxon maintenu)
    141332, -- Sparganium erectum (texte à garder => taxon maintenu)
    612583, -- Veratrum album (texte à garder => taxon maintenu)
    151867, -- Sisymbrium officinale (texte à garder => taxon maintenu)
    151868, -- Sisymbrium officinale (texte à garder => taxon maintenu)
    137541, -- Lycopus europaeus var.europaeus
    131383, -- Androsace vitaliana subsp.cinerea (texte à garder => taxon maintenu 82545)
    132482, -- Campanula glomerata subsp.glomerata (texte à garder => taxon maintenu 87652)
    132481, -- Campanula glomerata subsp.farinosa (texte à garder => taxon maintenu 87652)
    140668, -- Saxifraga oppositifolia subsp.oppositifolia (texte à garder => taxon maintenu 121132)
    612628, -- Scorzoneroides pyrenaica var.pyrenaica (texte à garder => taxon maintenu 611356)
    612627,-- Scorzoneroides pyrenaica var.helvetica (texte à garder => taxon maintenu 611356)
    140484 -- Salix triandra subsp. discolor (texte à garder => taxon maintenu 120246)
) ;

-- Reassociate attributs to new taxon
-- Amaranthus hybridus
UPDATE taxonomie.cor_taxon_attribut SET cd_ref = 81992 WHERE cd_ref = 131296 ;
-- Asarum europaeum
UPDATE taxonomie.cor_taxon_attribut SET cd_ref = 84230 WHERE cd_ref = 131752 ;
-- Dianthus armeria
UPDATE taxonomie.cor_taxon_attribut SET cd_ref = 94693 WHERE cd_ref = 133810 ;
-- Moenchia erecta
UPDATE taxonomie.cor_taxon_attribut SET cd_ref = 108703 WHERE cd_ref = 613153 ;


-- Associate deleted taxons photos to new taxons
-- Dianthus armeria
UPDATE taxonomie.t_medias SET cd_ref = 94693, id_type = 2 WHERE cd_ref = 133810 ;
-- Moenchia erecta
UPDATE taxonomie.t_medias SET cd_ref = 108703, id_type = 2 WHERE cd_ref = 613153 ;
-- Sagina saginoides
UPDATE taxonomie.t_medias SET cd_ref = 119827, id_type = 2 WHERE cd_ref = 140428 ;
-- Salix triandra
UPDATE taxonomie.t_medias SET cd_ref = 120246, id_type = 2 WHERE cd_ref = 140485 ;
-- Veratrum album
UPDATE taxonomie.t_medias SET cd_ref = 128520, id_type = 2 WHERE cd_ref = 612583 ;
-- Campanula glomerata
UPDATE taxonomie.t_medias SET cd_ref = 87652, id_type = 2 WHERE cd_ref = 132482 ;


-- Commit if all good
COMMIT;
