-- Migration TaxRef v17 vers v18 – PRÉ-DÉTECTION (par grappes, cas 3) – SINP AURA
BEGIN;

-- Désactivation des triggers sur la table synthese
ALTER TABLE gn_synthese.synthese DISABLE TRIGGER tri_meta_dates_change_synthese ;
ALTER TABLE gn_synthese.synthese DISABLE TRIGGER tri_update_calculate_sensitivity ;

-- ----------------------------------------------------------------
-- 1. Asparagus officinalis (cible : 84279)
DELETE FROM taxonomie.cor_taxon_attribut WHERE cd_ref IN (131756) AND id_attribut IN (106,107);
UPDATE taxonomie.t_medias SET cd_ref = 84279 WHERE cd_ref IN (131756);
DELETE FROM taxonomie.cor_nom_liste WHERE id_nom IN (SELECT id_nom FROM taxonomie.bib_noms WHERE cd_nom IN (131756));
DELETE FROM taxonomie.bib_noms WHERE cd_nom IN (131756);

-- ----------------------------------------------------------------
-- 2. Juncus bulbosus (cible : 104145)
DELETE FROM taxonomie.cor_taxon_attribut WHERE cd_ref IN (104156,104225,104345,104367,113317,136927,136928,136955,136957,147921,147923) AND id_attribut IN (107,106);
UPDATE taxonomie.t_medias SET cd_ref = 104145 WHERE cd_ref IN (104156,104225,104345,104367,113317,136927,136928,136955,136957,147921,147923);
DELETE FROM taxonomie.cor_nom_liste WHERE id_nom IN (SELECT id_nom FROM taxonomie.bib_noms WHERE cd_nom IN (104156,104225,104345,104367,113317,136927,136928,136955,136957,147921,147923));
DELETE FROM taxonomie.bib_noms WHERE cd_nom IN (104156,104225,104345,104367,113317,136927,136928,136955,136957,147921,147923);

-- ----------------------------------------------------------------
-- 3. Neotinea ustulata (cible : 109501)
DELETE FROM taxonomie.cor_taxon_attribut WHERE cd_ref IN (111012,138429,162137,718722) AND id_attribut IN (107,106);
UPDATE taxonomie.t_medias SET cd_ref = 109501 WHERE cd_ref IN (111012,138429,162137,718722);
DELETE FROM taxonomie.cor_nom_liste WHERE id_nom IN (SELECT id_nom FROM taxonomie.bib_noms WHERE cd_nom IN (111012,138429,162137,718722));
DELETE FROM taxonomie.bib_noms WHERE cd_nom IN (111012,138429,162137,718722);

-- ----------------------------------------------------------------
-- 4. Pulsatilla rubra (cible : 116456)
DELETE FROM taxonomie.cor_taxon_attribut WHERE cd_ref IN (82660,131408,139522,150342,150343,150351,155095,161705,718641,718642) AND id_attribut IN (107,106);
UPDATE taxonomie.t_medias SET cd_ref = 116456 WHERE cd_ref IN (82660,131408,139522,150342,150343,150351,155095,161705,718641,718642);
DELETE FROM taxonomie.cor_nom_liste WHERE id_nom IN (SELECT id_nom FROM taxonomie.bib_noms WHERE cd_nom IN (82660,131408,139522,150342,150343,150351,155095,161705,718641,718642));
DELETE FROM taxonomie.bib_noms WHERE cd_nom IN (82660,131408,139522,150342,150343,150351,155095,161705,718641,718642);

-- ----------------------------------------------------------------
-- 5. Reseda lutea (cible : 117458)
DELETE FROM taxonomie.cor_taxon_attribut WHERE cd_ref IN (117447,139857,150557) AND id_attribut IN (106,107,108);
UPDATE taxonomie.t_medias SET cd_ref = 117458 WHERE cd_ref IN (117447,139857,150557);
DELETE FROM taxonomie.cor_nom_liste WHERE id_nom IN (SELECT id_nom FROM taxonomie.bib_noms WHERE cd_nom IN (117447,139857,150557));
DELETE FROM taxonomie.bib_noms WHERE cd_nom IN (117447,139857,150557);

-- ----------------------------------------------------------------
-- 6. Rubia peregrina (cible : 118916)
DELETE FROM taxonomie.cor_taxon_attribut WHERE cd_ref IN (118909,140175) AND id_attribut IN (106,107);
UPDATE taxonomie.t_medias SET cd_ref = 118916 WHERE cd_ref IN (118909,140175);
DELETE FROM taxonomie.cor_nom_liste WHERE id_nom IN (SELECT id_nom FROM taxonomie.bib_noms WHERE cd_nom IN (118909,140175));
DELETE FROM taxonomie.bib_noms WHERE cd_nom IN (118909,140175);

-- ----------------------------------------------------------------
-- 7. Salix fragilis (cible : 120040)
DELETE FROM taxonomie.cor_taxon_attribut WHERE cd_ref IN (119946,119950,120263,120512,140439,151070,151071) AND id_attribut IN (107,106);
UPDATE taxonomie.t_medias SET cd_ref = 120040 WHERE cd_ref IN (119946,119950,120263,120512,140439,151070,151071);
DELETE FROM taxonomie.cor_nom_liste WHERE id_nom IN (SELECT id_nom FROM taxonomie.bib_noms WHERE cd_nom IN (119946,119950,120263,120512,140439,151070,151071));
DELETE FROM taxonomie.bib_noms WHERE cd_nom IN (119946,119950,120263,120512,140439,151070,151071);

-- ----------------------------------------------------------------
-- 8. Solanum nigrum (cible : 124080)
DELETE FROM taxonomie.cor_taxon_attribut WHERE cd_ref IN (124017,124083,141265,141273,141275,151896) AND id_attribut IN (107);
UPDATE taxonomie.t_medias SET cd_ref = 124080 WHERE cd_ref IN (124017,124083,141265,141273,141275,151896);
DELETE FROM taxonomie.cor_nom_liste WHERE id_nom IN (SELECT id_nom FROM taxonomie.bib_noms WHERE cd_nom IN (124017,124083,141265,141273,141275,151896));
DELETE FROM taxonomie.bib_noms WHERE cd_nom IN (124017,124083,141265,141273,141275,151896);

-- ----------------------------------------------------------------
-- 9. Thalictrum simplex (cible : 126213)
DELETE FROM taxonomie.cor_taxon_attribut WHERE cd_ref IN (126089,141635,141636,141638,718422) AND id_attribut IN (107,106);
UPDATE taxonomie.t_medias SET cd_ref = 126213 WHERE cd_ref IN (126089,141635,141636,141638,718422);
DELETE FROM taxonomie.cor_nom_liste WHERE id_nom IN (SELECT id_nom FROM taxonomie.bib_noms WHERE cd_nom IN (126089,141635,141636,141638,718422));
DELETE FROM taxonomie.bib_noms WHERE cd_nom IN (126089,141635,141636,141638,718422);

-- ----------------------------------------------------------------
-- 10. Urtica dioica (cible : 128268)
DELETE FROM taxonomie.cor_taxon_attribut WHERE cd_ref IN (128275,142037,142038) AND id_attribut IN (107,108,106);
UPDATE taxonomie.t_medias SET cd_ref = 128268 WHERE cd_ref IN (128275,142037,142038);
DELETE FROM taxonomie.cor_nom_liste WHERE id_nom IN (SELECT id_nom FROM taxonomie.bib_noms WHERE cd_nom IN (128275,142037,142038));
DELETE FROM taxonomie.bib_noms WHERE cd_nom IN (128275,142037,142038);

COMMIT;
