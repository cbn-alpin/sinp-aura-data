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


-- Remove attributs
DELETE FROM taxonomie.cor_taxon_attribut WHERE cd_ref IN (
    81992, -- Amaranthus hybridus L., 1753 (texte à garder => taxon supprimé)
    84230, -- Asarum europaeum L., 1753 (texte à garder => taxon supprimé)
    94693, -- Dianthus armeria L., 1753(texte à garder => taxon supprimé)
    148559, -- Medicago minima (L.) L., 1754 (texte à garder => taxon maintenu)
    108703, -- Moenchia erecta (L.) G.Gaertn., B.Mey.& Scherb., 1799 (texte à garder => taxon supprimé)
    140428, -- Sagina saginoides (L.) H.Karst., 1882 (texte à garder = > taxon maintenu)
    140485, -- Salix triandra L., 1753 (texte à garder = > taxon maintenu)
    141332, -- Sparganium erectum L., 1753 (texte à garder = > taxon maintenu)
    612583, -- Veratrum album L., 1753 (texte à garder = > taxon maintenu)
    151867, -- Sisymbrium officinale (L.) Scop., 1772 (texte à garder = > taxon maintenu)
    151868 -- Sisymbrium officinale (L.) Scop., 1772 (texte à garder = > taxon maintenu)
) ;
-- Amaranthus hybridus L., 1753
UPDATE taxonomie.cor_taxon_attribut SET cd_ref = 81992 WHERE cd_ref = 131296 ;
-- Asarum europaeum L., 1753
UPDATE taxonomie.cor_taxon_attribut SET cd_ref = 84230 WHERE cd_ref = 131752 ;
-- Dianthus armeria L., 1753
UPDATE taxonomie.cor_taxon_attribut SET cd_ref = 94693 WHERE cd_ref = 133810 ;
-- Moenchia erecta (L.) G.Gaertn., B.Mey.& Scherb., 1799
UPDATE taxonomie.cor_taxon_attribut SET cd_ref = 108703 WHERE cd_ref = 613153 ;


-- Associate deleted taxons photos to new taxons
-- Dianthus armeria L., 1753
UPDATE taxonomie.t_medias SET cd_ref = 94693, id_type = 2 WHERE cd_ref = 133810 ;
-- Moenchia erecta (L.) G.Gaertn., B.Mey.& Scherb., 1799
UPDATE taxonomie.t_medias SET cd_ref = 108703, id_type = 2 WHERE cd_ref = 613153 ;
-- Sagina saginoides (L.) H.Karst., 1882
UPDATE taxonomie.t_medias SET cd_ref = 119827, id_type = 2 WHERE cd_ref = 140428 ;
-- Salix triandra L., 1753
UPDATE taxonomie.t_medias SET cd_ref = 120246, id_type = 2 WHERE cd_ref = 140485 ;
-- Veratrum album L., 1753
UPDATE taxonomie.t_medias SET cd_ref = 128520, id_type = 2 WHERE cd_ref = 612583 ;


-- Commit if all good
COMMIT;
