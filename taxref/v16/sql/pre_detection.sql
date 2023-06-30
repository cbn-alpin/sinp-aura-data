-- Mise à jour TaxRef v15 vers v16 pour le SINP AURA
BEGIN;

-- Disable trigger "tri_meta_dates_change_synthese"
ALTER TABLE gn_synthese.synthese DISABLE TRIGGER tri_meta_dates_change_synthese ;

-- Disable trigger "tri_update_calculate_sensitivity"
ALTER TABLE gn_synthese.synthese DISABLE TRIGGER tri_update_calculate_sensitivity ;

-- Drop constraint on "cd_nom" field of  "synthese" table because we update cd_nom not yet in "taxref" table.
ALTER TABLE gn_synthese.synthese DROP CONSTRAINT IF EXISTS fk_synthese_cd_nom;

-- -------------------------------------------------------------------------------------------------
-- Manage taxonomie.cdnom_disparu.cd_raison_suppression = 1, 2 or 3

-- SYNTHESE
-- Set cd_nom to NULL for removing TaxRef cd_nom (cd_raison_suppression = 2 or 3)
UPDATE gn_synthese.synthese
SET cd_nom = NULL
WHERE cd_nom IN (88410, 101626, 106344, 107310, 110895, 118953, 122145, 137835, 436045, 436047, 787051, 788037);

-- Update rows with replacement cd_nom in synthese (cd_raison_suppression = 1)
UPDATE gn_synthese.synthese SET cd_nom = 83482 WHERE cd_nom = 83483 ;
UPDATE gn_synthese.synthese SET cd_nom = 83528 WHERE cd_nom = 83527 ;
UPDATE gn_synthese.synthese SET cd_nom = 619051 WHERE cd_nom = 89860 ;
UPDATE gn_synthese.synthese SET cd_nom = 619337 WHERE cd_nom = 96528 ;
UPDATE gn_synthese.synthese SET cd_nom = 619337 WHERE cd_nom = 96530 ;
UPDATE gn_synthese.synthese SET cd_nom = 97289 WHERE cd_nom = 97290 ;
UPDATE gn_synthese.synthese SET cd_nom = 717248 WHERE cd_nom = 102114 ;
UPDATE gn_synthese.synthese SET cd_nom = 109428 WHERE cd_nom = 109427 ;
UPDATE gn_synthese.synthese SET cd_nom = 113212 WHERE cd_nom = 113211 ;
UPDATE gn_synthese.synthese SET cd_nom = 161830 WHERE cd_nom = 119441 ;
UPDATE gn_synthese.synthese SET cd_nom = 103674 WHERE cd_nom = 126918 ;
UPDATE gn_synthese.synthese SET cd_nom = 142583 WHERE cd_nom = 130819 ;
UPDATE gn_synthese.synthese SET cd_nom = 612619 WHERE cd_nom = 134199 ;
UPDATE gn_synthese.synthese SET cd_nom = 619867 WHERE cd_nom = 137347 ;
UPDATE gn_synthese.synthese SET cd_nom = 611221 WHERE cd_nom = 159642 ;
UPDATE gn_synthese.synthese SET cd_nom = 463673 WHERE cd_nom = 463664 ;
UPDATE gn_synthese.synthese SET cd_nom = 463867 WHERE cd_nom = 463887 ;
UPDATE gn_synthese.synthese SET cd_nom = 464913 WHERE cd_nom = 464912 ;
UPDATE gn_synthese.synthese SET cd_nom = 142242 WHERE cd_nom = 611982 ;
UPDATE gn_synthese.synthese SET cd_nom = 89579 WHERE cd_nom = 613650 ;
UPDATE gn_synthese.synthese SET cd_nom = 89653 WHERE cd_nom = 613655 ;
UPDATE gn_synthese.synthese SET cd_nom = 80713 WHERE cd_nom = 613771 ;
UPDATE gn_synthese.synthese SET cd_nom = 108151 WHERE cd_nom = 637815 ;
UPDATE gn_synthese.synthese SET cd_nom = 109422 WHERE cd_nom = 773798 ;
UPDATE gn_synthese.synthese SET cd_nom = 100572 WHERE cd_nom = 921710 ;

-- -------------------------------------------------------------------------------------------------
-- Replace cd_nom by new TaxRef v16 cd_nom then delete old cd_nom
-- See https://github.com/PnX-SI/TaxHub/issues/407

-- Add new cd_nom to current taxref (v15) to pass test
INSERT INTO taxonomie.taxref (
    cd_nom, id_statut, id_habitat, id_rang, regne, phylum, classe, ordre, famille, sous_famille,
    tribu, cd_taxsup, cd_sup, cd_ref, lb_nom, lb_auteur, nom_complet, nom_complet_html, nom_valide,
    nom_vern, nom_vern_eng, group1_inpn, group2_inpn, url, group3_inpn
) VALUES (
    1008910, 'P', 3, 'ES', 'Plantae', NULL, 'Equisetopsida', 'Ericales', 'Ericaceae',
    'Vaccinioideae', 'Vaccinieae', NULL, NULL, 128347, 'Oxycoccus vulgaris',
    'Pursh, 1813 [nom. illeg. superfl.]', 'Oxycoccus vulgaris Pursh, 1813 [nom. illeg. superfl.]',
    '<i>Oxycoccus vulgaris</i> Pursh, 1813 [nom. illeg. superfl.]',
    'Vaccinium oxycoccos L., 1753',
    'Airelle canneberge, Canneberge à gros fruits, Canneberge commune',
    'Cranberry', 'Trachéophytes', 'Angiospermes', 'https://inpn.mnhn.fr/espece/cd_nom/1008910',
    'Autres'
);

-- Replace old removing cd_nom by new cd_nom
UPDATE gn_synthese.synthese SET
    cd_nom = 1008910
WHERE cd_nom = 111955 ;

-- -------------------------------------------------------------------------------------------------
-- Issues in TaxRev v16 files
-- See https://github.com/PnX-SI/TaxHub/issues/407
UPDATE gn_synthese.synthese SET
    cd_nom = NULL,
    additional_data = jsonb_set(
        additional_data,
        '{taxrefUpdate}',
        jsonb_build_object('version', 16, 'previousCdNom', 129323),
        true
    )
WHERE cd_nom = 129323 ;

-- -------------------------------------------------------------------------------------------------
-- BIB_NOMS
-- Deleting rows in "cor_nom_liste" for all kinds of conflicts (see below bib_noms):
-- - obsolete cd_name + cd_ref association : 88591, 93599, 93653, 133568, 95763, 103278
-- - cd_nom deleted (cd_raison_suppression = 1,2,3) : others
DELETE FROM taxonomie.cor_nom_liste AS l
WHERE l.id_nom IN (
    SELECT id_nom
    FROM taxonomie.bib_noms
    WHERE cd_nom IN (
        88591, 93599, 93653, 133568, 95763, 103278,
        83483, 83527, 89860, 96528, 96530, 97290, 102114, 109427, 111955, 113211, 119441, 126918,
        130819, 134199, 137347, 159642, 463664, 463887, 464912, 611982, 613650, 613655, 613771,
        637815, 773798, 921710,
        88410, 101626, 106344, 107310, 110895, 118928, 118946, 118953, 118981, 122145, 137835,
        436045, 436047, 787051, 788037, 956743
    )
) ;

-- Deleting rows in "taxonomie.bib_noms" for all kinds of conflicts because:
-- "taxonomie.bib_noms" is only used in SINP for Taxhub INPN medias dowload script.
-- "taxonomie.bib_noms" must be recreated from gn_synthese.synthese if necessary.
DELETE FROM taxonomie.bib_noms
WHERE cd_nom IN (
    88591, 93599, 93653, 133568, 95763, 103278,
    83483, 83527, 89860, 96528, 96530, 97290, 102114, 109427, 111955, 113211, 119441, 126918,
    130819, 134199, 137347, 159642, 463664, 463887, 464912, 611982, 613650, 613655, 613771,
    637815, 773798, 921710,
    88410, 101626, 106344, 107310, 110895, 118928, 118946, 118953, 118981, 122145, 137835,
        436045, 436047, 787051, 788037, 956743
) ;

-- -------------------------------------------------------------------------------------------------
-- Manage Attributs

-- Remove useless attributs
DELETE FROM taxonomie.cor_taxon_attribut WHERE cd_ref IN (
    134355, -- Euphorbia chamaesyce subsp. chamaesyce
    138815, -- Pinguicula grandiflora subsp. grandiflora
    621498, -- Pinguicula grandiflora var. pallida
    923321  -- Pinguicula grandiflora var. grandiflora
) ;

-- -------------------------------------------------------------------------------------------------
-- Manage Media

-- Associate deleted taxons photos to new taxons
-- Euphorbia chamaesyce subsp. chamaesyce
UPDATE taxonomie.t_medias SET cd_ref = 97477, id_type = 2 WHERE cd_ref = 134355 ;
-- Pinguicula grandiflora subsp. grandiflora
UPDATE taxonomie.t_medias SET cd_ref = 113620, id_type = 2 WHERE cd_ref = 138815 ;
-- Pinguicula grandiflora var. pallida
UPDATE taxonomie.t_medias SET cd_ref = 113620, id_type = 2 WHERE cd_ref = 621498 ;
-- Pinguicula grandiflora var. grandiflora
UPDATE taxonomie.t_medias SET cd_ref = 113620, id_type = 2 WHERE cd_ref = 923321 ;

-- -------------------------------------------------------------------------------------------------
-- Commit if all good
COMMIT;
