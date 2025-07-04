-- Migration TaxRef v17 vers v18 – Pré-détection, résolution des conflits et nettoyage – SINP AURA

BEGIN;

-- ----------------------------------------------------------------
-- 0. Désactivation des triggers sur la table synthese
ALTER TABLE gn_synthese.synthese DISABLE TRIGGER tri_meta_dates_change_synthese;
ALTER TABLE gn_synthese.synthese DISABLE TRIGGER tri_update_calculate_sensitivity;

-- ----------------------------------------------------------------
-- 0bis. Suppression des contraintes FK et CHECK (pour t_medias, synthese, bib_noms)
ALTER TABLE gn_synthese.synthese DROP CONSTRAINT IF EXISTS fk_synthese_cd_nom;
ALTER TABLE taxonomie.t_medias DROP CONSTRAINT IF EXISTS fk_t_media_bib_noms;
ALTER TABLE taxonomie.t_medias DROP CONSTRAINT IF EXISTS check_is_cd_ref;
ALTER TABLE taxonomie.bib_noms DROP CONSTRAINT IF EXISTS bib_noms_cd_nom_key;
ALTER TABLE taxonomie.bib_noms DROP CONSTRAINT IF EXISTS fk_bib_nom_taxref;
-- ----------------------------------------------------------------
-- 1. Asparagus officinalis (cible : 84279)
DELETE FROM taxonomie.cor_taxon_attribut 
WHERE cd_ref IN (131756)
  AND id_attribut IN (
        taxonomie.get_id_attribut_by_name('sinp_description'),
        taxonomie.get_id_attribut_by_name('sinp_ecology'),
        taxonomie.get_id_attribut_by_name('sinp_habitat'),
        taxonomie.get_id_attribut_by_name('sinp_uses')
  );
UPDATE taxonomie.t_medias SET cd_ref = 84279 WHERE cd_ref IN (131756);

-- ----------------------------------------------------------------
-- 2. Juncus bulbosus (cible : 104145)
DELETE FROM taxonomie.cor_taxon_attribut 
WHERE cd_ref IN (136927,136928)
  AND id_attribut IN (
        taxonomie.get_id_attribut_by_name('sinp_description'),
        taxonomie.get_id_attribut_by_name('sinp_ecology'),
        taxonomie.get_id_attribut_by_name('sinp_habitat'),
        taxonomie.get_id_attribut_by_name('sinp_uses')
  );
UPDATE taxonomie.t_medias SET cd_ref = 104145 WHERE cd_ref IN (136927,136928);

-- ----------------------------------------------------------------
-- 3. Neotinea ustulata (cible : 109501)
DELETE FROM taxonomie.cor_taxon_attribut 
WHERE cd_ref IN (162137,718722)
  AND id_attribut IN (
        taxonomie.get_id_attribut_by_name('sinp_description'),
        taxonomie.get_id_attribut_by_name('sinp_ecology'),
        taxonomie.get_id_attribut_by_name('sinp_habitat'),
        taxonomie.get_id_attribut_by_name('sinp_uses')
  );
UPDATE taxonomie.t_medias SET cd_ref = 109501 WHERE cd_ref IN (162137,718722);

-- ----------------------------------------------------------------
-- 4. Pulsatilla rubra (cible : 116456)
DELETE FROM taxonomie.cor_taxon_attribut 
WHERE cd_ref IN (150342,150343)
  AND id_attribut IN (
        taxonomie.get_id_attribut_by_name('sinp_description'),
        taxonomie.get_id_attribut_by_name('sinp_ecology'),
        taxonomie.get_id_attribut_by_name('sinp_habitat'),
        taxonomie.get_id_attribut_by_name('sinp_uses')
  );
UPDATE taxonomie.t_medias SET cd_ref = 116456 WHERE cd_ref IN (150342,150343);

-- ----------------------------------------------------------------
-- 5. Reseda lutea (cible : 117458)
DELETE FROM taxonomie.cor_taxon_attribut 
WHERE cd_ref IN (139857)
  AND id_attribut IN (
        taxonomie.get_id_attribut_by_name('sinp_description'),
        taxonomie.get_id_attribut_by_name('sinp_ecology'),
        taxonomie.get_id_attribut_by_name('sinp_habitat'),
        taxonomie.get_id_attribut_by_name('sinp_uses')
  );
UPDATE taxonomie.t_medias SET cd_ref = 117458 WHERE cd_ref IN (139857);

-- ----------------------------------------------------------------
-- 6. Rubia peregrina (cible : 118916)
DELETE FROM taxonomie.cor_taxon_attribut 
WHERE cd_ref IN (140175)
  AND id_attribut IN (
        taxonomie.get_id_attribut_by_name('sinp_description'),
        taxonomie.get_id_attribut_by_name('sinp_ecology'),
        taxonomie.get_id_attribut_by_name('sinp_habitat'),
        taxonomie.get_id_attribut_by_name('sinp_uses')
  );
UPDATE taxonomie.t_medias SET cd_ref = 118916 WHERE cd_ref IN (140175);

-- ----------------------------------------------------------------
-- 7. Salix fragilis (cible : 120040)
DELETE FROM taxonomie.cor_taxon_attribut 
WHERE cd_ref IN (120512)
  AND id_attribut IN (
        taxonomie.get_id_attribut_by_name('sinp_description'),
        taxonomie.get_id_attribut_by_name('sinp_ecology'),
        taxonomie.get_id_attribut_by_name('sinp_habitat'),
        taxonomie.get_id_attribut_by_name('sinp_uses')
  );
UPDATE taxonomie.t_medias SET cd_ref = 120040 WHERE cd_ref IN (120512);

-- ----------------------------------------------------------------
-- 8. Solanum nigrum (cible : 124080)
DELETE FROM taxonomie.cor_taxon_attribut 
WHERE cd_ref IN (141273,141275)
  AND id_attribut IN (
        taxonomie.get_id_attribut_by_name('sinp_description'),
        taxonomie.get_id_attribut_by_name('sinp_ecology'),
        taxonomie.get_id_attribut_by_name('sinp_habitat'),
        taxonomie.get_id_attribut_by_name('sinp_uses')
  );
UPDATE taxonomie.t_medias SET cd_ref = 124080 WHERE cd_ref IN (141273,141275);

-- ----------------------------------------------------------------
-- 9. Thalictrum simplex (cible : 126213)
DELETE FROM taxonomie.cor_taxon_attribut 
WHERE cd_ref IN (141636,141638,718422)
  AND id_attribut IN (
        taxonomie.get_id_attribut_by_name('sinp_description'),
        taxonomie.get_id_attribut_by_name('sinp_ecology'),
        taxonomie.get_id_attribut_by_name('sinp_habitat'),
        taxonomie.get_id_attribut_by_name('sinp_uses')
  );
UPDATE taxonomie.t_medias SET cd_ref = 126213 WHERE cd_ref IN (141636,141638,718422);

-- ----------------------------------------------------------------
-- 10. Urtica dioica (cible : 128268)
DELETE FROM taxonomie.cor_taxon_attribut 
WHERE cd_ref IN (142037,142038)
  AND id_attribut IN (
        taxonomie.get_id_attribut_by_name('sinp_description'),
        taxonomie.get_id_attribut_by_name('sinp_ecology'),
        taxonomie.get_id_attribut_by_name('sinp_habitat'),
        taxonomie.get_id_attribut_by_name('sinp_uses')
  );
UPDATE taxonomie.t_medias SET cd_ref = 128268 WHERE cd_ref IN (142037,142038);

-- ----------------------------------------------------------------
-- Résolution des orphelins et remplacements génériques

-- gn_sensitivity.t_sensitivity_rules
UPDATE gn_sensitivity.t_sensitivity_rules SET cd_nom = 124412 WHERE cd_nom = 124413;
UPDATE gn_sensitivity.t_sensitivity_rules SET cd_nom = 138121 WHERE cd_nom = 718726;

-- gn_synthese.synthese : neutralisation/remplacement
UPDATE gn_synthese.synthese
SET cd_nom = NULL
WHERE cd_nom IN (
    41508, 46412, 46608, 59404, 96518, 98692, 99589, 104154, 110344, 110424, 110991, 114417,
    117011, 119429, 122827, 124262, 124413, 126163, 126212, 129108, 129226, 129579, 131837, 233536,
    234037, 138395, 147083, 162283, 660054, 660095, 873328, 945104, 103706, 83018, 87931, 88315,
    119398, 121607, 130237, 130415, 620446, 129530, 719293, 461959
);
UPDATE gn_synthese.synthese SET cd_nom = 159607 WHERE cd_nom = 92267;
UPDATE gn_synthese.synthese SET cd_nom = 110473 WHERE cd_nom = 110474;
UPDATE gn_synthese.synthese SET cd_nom = 1056537 WHERE cd_nom = 117281;
UPDATE gn_synthese.synthese SET cd_nom = 621429 WHERE cd_nom = 129770;
UPDATE gn_synthese.synthese SET cd_nom = 773729 WHERE cd_nom = 136960;
UPDATE gn_synthese.synthese SET cd_nom = 457300 WHERE cd_nom = 233651;
UPDATE gn_synthese.synthese SET cd_nom = 233652 WHERE cd_nom = 457301;
UPDATE gn_synthese.synthese SET cd_nom = 233656 WHERE cd_nom = 457302;
UPDATE gn_synthese.synthese SET cd_nom = 57077 WHERE cd_nom = 658461;
UPDATE gn_synthese.synthese SET cd_nom = 59428 WHERE cd_nom = 660113;

-- Nettoyage cor_nom_liste puis bib_noms pour les orphelins
DELETE FROM taxonomie.cor_nom_liste WHERE id_nom IN (
    SELECT id_nom FROM taxonomie.bib_noms WHERE cd_nom IN (
        41508, 46412, 46608, 59404, 96518, 98692,
        99589, 104154, 110344, 110424, 110991, 114417,
        117011, 119429, 122827, 124262, 124413, 126163,
        126212, 129108, 129226, 129579, 131837, 233536,
        234037, 138395, 147083, 162283, 660054, 660095,
        873328, 945104, 103706, 83018, 87931, 88315,
        119398, 121607, 130237, 130415, 620446, 129530,
        719293, 461959, 92267, 110474, 117281, 129770,
        136960, 233651, 457301, 457302, 658461, 660113,
        125814
    )
);
DELETE FROM taxonomie.bib_noms WHERE cd_nom IN (
    41508, 46412, 46608, 59404, 96518, 98692,
    99589, 104154, 110344, 110424, 110991, 114417,
    117011, 119429, 122827, 124262, 124413, 126163,
    126212, 129108, 129226, 129579, 131837, 233536,
    234037, 138395, 147083, 162283, 660054, 660095,
    873328, 945104, 103706, 83018, 87931, 88315,
    119398, 121607, 130237, 130415, 620446, 129530,
    719293, 461959, 92267, 110474, 117281, 129770,
    136960, 233651, 457301, 457302, 658461, 660113,
    125814
);

COMMIT;

-- ----------------------------------------------------------------
-- *** IMPORTANT ***
-- Après l'import de la nouvelle table TaxRef (v18) et vérification des données,
-- exécuter reactivation_contraintes_apres_taxref.sql