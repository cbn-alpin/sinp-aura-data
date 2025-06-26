-- Migration TaxRef v17 vers v18 – PRÉ-DÉTECTION (par grappes, cas 3) – SINP AURA
-- Adapté pour n'utiliser que la logique dynamique sur les attributs (robuste/portable)
-- NE PAS toucher à taxonomie.bib_noms et taxonomie.cor_nom_liste ici (nettoyage post-migration)

BEGIN;

-- Désactivation des triggers sur la table synthese
ALTER TABLE gn_synthese.synthese DISABLE TRIGGER tri_meta_dates_change_synthese ;
ALTER TABLE gn_synthese.synthese DISABLE TRIGGER tri_update_calculate_sensitivity ;

-- Attributs concernés pour les suppressions cas 3
-- (ajoute ou retire ici selon besoin : tous les noms sont dynamiques, pas d'id en dur)
-- Par défaut, on traite les attributs classiques de fusion/finalité
-- ('sinp_description', 'sinp_ecology', 'sinp_habitat' sont des exemples fréquents)
-- Tu peux factoriser la liste dans chaque grappe si besoin (ou la mettre en variable si tu fais du SQL dynamique)

-- ----------------------------------------------------------------
-- 1. Asparagus officinalis (cible : 84279)
DELETE FROM taxonomie.cor_taxon_attribut 
WHERE cd_ref IN (131756)
  AND id_attribut IN (
        taxonomie.get_id_attribut_by_name('sinp_description'),
        taxonomie.get_id_attribut_by_name('sinp_ecology')
  );
UPDATE taxonomie.t_medias SET cd_ref = 84279 WHERE cd_ref IN (131756);

-- ----------------------------------------------------------------
-- 2. Juncus bulbosus (cible : 104145)
DELETE FROM taxonomie.cor_taxon_attribut 
WHERE cd_ref IN (104156,104225,104345,104367,113317,136927,136928,136955,136957,147921,147923)
  AND id_attribut IN (
        taxonomie.get_id_attribut_by_name('sinp_description'),
        taxonomie.get_id_attribut_by_name('sinp_ecology')
  );
UPDATE taxonomie.t_medias SET cd_ref = 104145 WHERE cd_ref IN (104156,104225,104345,104367,113317,136927,136928,136955,136957,147921,147923);

-- ----------------------------------------------------------------
-- 3. Neotinea ustulata (cible : 109501)
DELETE FROM taxonomie.cor_taxon_attribut 
WHERE cd_ref IN (111012,138429,162137,718722)
  AND id_attribut IN (
        taxonomie.get_id_attribut_by_name('sinp_description'),
        taxonomie.get_id_attribut_by_name('sinp_ecology')
  );
UPDATE taxonomie.t_medias SET cd_ref = 109501 WHERE cd_ref IN (111012,138429,162137,718722);

-- ----------------------------------------------------------------
-- 4. Pulsatilla rubra (cible : 116456)
DELETE FROM taxonomie.cor_taxon_attribut 
WHERE cd_ref IN (82660,131408,139522,150342,150343,150351,155095,161705,718641,718642)
  AND id_attribut IN (
        taxonomie.get_id_attribut_by_name('sinp_description'),
        taxonomie.get_id_attribut_by_name('sinp_ecology')
  );
UPDATE taxonomie.t_medias SET cd_ref = 116456 WHERE cd_ref IN (82660,131408,139522,150342,150343,150351,155095,161705,718641,718642);

-- ----------------------------------------------------------------
-- 5. Reseda lutea (cible : 117458)
DELETE FROM taxonomie.cor_taxon_attribut 
WHERE cd_ref IN (117447,139857,150557)
  AND id_attribut IN (
        taxonomie.get_id_attribut_by_name('sinp_description'),
        taxonomie.get_id_attribut_by_name('sinp_ecology'),
        taxonomie.get_id_attribut_by_name('sinp_habitat')
  );
UPDATE taxonomie.t_medias SET cd_ref = 117458 WHERE cd_ref IN (117447,139857,150557);

-- ----------------------------------------------------------------
-- 6. Rubia peregrina (cible : 118916)
DELETE FROM taxonomie.cor_taxon_attribut 
WHERE cd_ref IN (118909,140175)
  AND id_attribut IN (
        taxonomie.get_id_attribut_by_name('sinp_description'),
        taxonomie.get_id_attribut_by_name('sinp_ecology')
  );
UPDATE taxonomie.t_medias SET cd_ref = 118916 WHERE cd_ref IN (118909,140175);

-- ----------------------------------------------------------------
-- 7. Salix fragilis (cible : 120040)
DELETE FROM taxonomie.cor_taxon_attribut 
WHERE cd_ref IN (119946,119950,120263,120512,140439,151070,151071)
  AND id_attribut IN (
        taxonomie.get_id_attribut_by_name('sinp_description'),
        taxonomie.get_id_attribut_by_name('sinp_ecology')
  );
UPDATE taxonomie.t_medias SET cd_ref = 120040 WHERE cd_ref IN (119946,119950,120263,120512,140439,151070,151071);

-- ----------------------------------------------------------------
-- 8. Solanum nigrum (cible : 124080)
DELETE FROM taxonomie.cor_taxon_attribut 
WHERE cd_ref IN (124017,124083,141265,141273,141275,151896)
  AND id_attribut IN (
        taxonomie.get_id_attribut_by_name('sinp_description'),
        taxonomie.get_id_attribut_by_name('sinp_ecology')
  );
UPDATE taxonomie.t_medias SET cd_ref = 124080 WHERE cd_ref IN (124017,124083,141265,141273,141275,151896);

-- ----------------------------------------------------------------
-- 9. Thalictrum simplex (cible : 126213)
DELETE FROM taxonomie.cor_taxon_attribut 
WHERE cd_ref IN (126089,141635,141636,141638,718422)
  AND id_attribut IN (
        taxonomie.get_id_attribut_by_name('sinp_description'),
        taxonomie.get_id_attribut_by_name('sinp_ecology')
  );
UPDATE taxonomie.t_medias SET cd_ref = 126213 WHERE cd_ref IN (126089,141635,141636,141638,718422);

-- ----------------------------------------------------------------
-- 10. Urtica dioica (cible : 128268)
DELETE FROM taxonomie.cor_taxon_attribut 
WHERE cd_ref IN (128275,142037,142038)
  AND id_attribut IN (
        taxonomie.get_id_attribut_by_name('sinp_description'),
        taxonomie.get_id_attribut_by_name('sinp_ecology'),
        taxonomie.get_id_attribut_by_name('sinp_habitat')
  );
UPDATE taxonomie.t_medias SET cd_ref = 128268 WHERE cd_ref IN (128275,142037,142038);

-- ----------------------------------------------------------------

COMMIT;
