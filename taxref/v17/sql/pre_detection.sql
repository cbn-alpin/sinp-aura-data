-- Mise à jour TaxRef v16 vers v17 pour le SINP AURA
BEGIN;

-- Database change in TaxHub v1.14.0
DROP TABLE IF EXISTS taxonomie.t_meta_taxref ;

CREATE TABLE taxonomie.t_meta_taxref (
    referencial_name varchar NOT NULL,
    "version" int4 NOT NULL,
    update_date timestamp DEFAULT now() NULL,
    CONSTRAINT t_meta_taxref_pkey PRIMARY KEY (referencial_name, version)
);

WITH meta_taxref AS (
    SELECT 1019039 as max_cd_nom, 16 AS taxref_version
    UNION
    SELECT 1002708  as max_cd_nom, 15 AS taxref_version
    UNION
    SELECT 972486  as max_cd_nom, 14 AS taxref_version
    UNION
    SELECT 935095  as max_cd_nom, 13 AS taxref_version
    UNION
    SELECT 887126  as max_cd_nom, 11 AS taxref_version
)
INSERT INTO taxonomie.t_meta_taxref (referencial_name, version)
    SELECT 'taxref', m.taxref_version
    FROM taxonomie.taxref AS t
        JOIN meta_taxref AS m
            ON t.cd_nom = m.max_cd_nom
    ORDER BY t.cd_nom DESC
    LIMIT 1;


-- Disable trigger "tri_meta_dates_change_synthese"
ALTER TABLE gn_synthese.synthese DISABLE TRIGGER tri_meta_dates_change_synthese ;

-- Disable trigger "tri_update_calculate_sensitivity"
ALTER TABLE gn_synthese.synthese DISABLE TRIGGER tri_update_calculate_sensitivity ;

-- Drop constraint on "cd_ref" field of "t_medias" table because we change cd_ref not yet in "taxref" table.
ALTER TABLE taxonomie.t_medias DROP CONSTRAINT IF EXISTS check_is_cd_ref ;

-- -------------------------------------------------------------------------------------------------
-- Utils functions
CREATE OR REPLACE FUNCTION taxonomie.get_id_attribut_by_name(attName character varying)
    RETURNS integer
    LANGUAGE plpgsql
    IMMUTABLE
AS
$function$
    -- Function which return the id_attribut from Taxhub Attributs
    DECLARE idAttribut integer;

    BEGIN
        SELECT INTO idAttribut id_attribut
        FROM taxonomie.bib_attributs
        WHERE nom_attribut = attName ;

        RETURN idAttribut ;
    END;
$function$ ;


-- -------------------------------------------------------------------------------------------------
--  Manage TaxRef

-- Add new cd_nom to current taxref (v16) to pass test
INSERT INTO taxonomie.taxref (
    cd_nom, id_statut, id_habitat, id_rang, regne, phylum, classe, ordre, famille, sous_famille,
    tribu, cd_taxsup, cd_sup, cd_ref, lb_nom, lb_auteur, nom_complet, nom_complet_html, nom_valide,
    nom_vern, nom_vern_eng, group1_inpn, group2_inpn, url, group3_inpn
)
    SELECT
        cd_nom, fr, habitat::int, rang, regne, phylum, classe, ordre, famille, sous_famille,
        tribu, cd_taxsup, cd_sup, cd_ref, lb_nom, lb_auteur, nom_complet, nom_complet_html, nom_valide,
        nom_vern, nom_vern_eng, group1_inpn, group2_inpn, url, group3_inpn
    FROM taxonomie.import_taxref
    WHERE cd_nom IN (1038698, 1027822)
ON CONFLICT (cd_nom) DO NOTHING ;

-- Change cd_ref in current taxref (v16) to enable check_is_cd_ref on
-- taxonomie.t_medias or taxonomie.cor_taxon_attribut
-- See https://github.com/PnX-SI/TaxHub/issues/495
UPDATE taxonomie.taxref SET cd_ref = 95557 WHERE cd_nom = 95557 ;
UPDATE taxonomie.taxref SET cd_ref = 112736 WHERE cd_nom = 112736 ;
UPDATE taxonomie.taxref SET cd_ref = 133622 WHERE cd_nom = 133622 ;

-- Change cd_ref in current taxref (v16) to avoid Conflict caused by split and merge
-- This updates are net necessary with branche fix/migrate_taxref !
-- UPDATE taxonomie.taxref SET cd_ref = 718332 WHERE cd_nom = 87354 ;

-- -------------------------------------------------------------------------------------------------
-- Manage taxonomie.cdnom_disparu.cd_raison_suppression = 1, 2 or 3
-- File: missing_cd_nom_into_database.csv

-- SYNTHESE
-- Set cd_nom to NULL for removing TaxRef cd_nom (cd_raison_suppression = 2 or 3)
UPDATE gn_synthese.synthese
SET cd_nom = NULL
WHERE cd_nom IN (
    85841, 85893, 85914, 85922, 90788, 94956, 95552, 108159, 108225, 108258, 108284, 108288,
    108290, 108324, 108997, 109517, 110477, 116017, 119138, 119168, 119177, 119268, 124829, 141567,
    469860, 607025, 199049, 884045,
    95583, 108148, 109692, 141571, 718789
);

-- Update rows with replacement cd_nom in synthese (cd_raison_suppression = 1)
UPDATE gn_synthese.synthese SET cd_nom = 789254 WHERE cd_nom = 104596 ;
UPDATE gn_synthese.synthese SET cd_nom = 978967 WHERE cd_nom = 109829 ;
UPDATE gn_synthese.synthese SET cd_nom = 113708 WHERE cd_nom = 113709 ;
UPDATE gn_synthese.synthese SET cd_nom = 614970 WHERE cd_nom = 114383 ;


-- -------------------------------------------------------------------------------------------------
-- Manage BIB_NOMS

-- Insert new taxon in bib_nom for constraint "fk_t_media_bib_noms" of "t_medias" table.
-- For new names retained (see "Manage TaxRef" section above here)
INSERT INTO taxonomie.bib_noms (cd_nom, cd_ref) VALUES
    (1038698, 1038698),
    (1027822, 1027822),
    (133622, 133622)
ON CONFLICT DO NOTHING ;

-- Change non compatible bib_noms rows (old cd_ref) with new TaxRef version
UPDATE taxonomie.bib_noms SET cd_ref = 1038698 WHERE cd_nom = 133969 AND cd_ref = 133969 ;
UPDATE taxonomie.bib_noms SET cd_ref = 95557 WHERE cd_nom = 133970 AND cd_ref = 133970 ;

-- Update rows with replacement cd_nom in synthese (cd_raison_suppression = 1)
UPDATE taxonomie.bib_noms SET cd_nom = 789254 WHERE cd_nom = 104596 ;
UPDATE taxonomie.bib_noms SET cd_nom = 978967 WHERE cd_nom = 109829 ;
-- UPDATE taxonomie.bib_noms SET cd_nom = 113708 WHERE cd_nom = 113709 ; -- Already exists => deleting !
-- UPDATE taxonomie.bib_noms SET cd_nom = 614970 WHERE cd_nom = 114383 ; -- Already exists => deleting !


-- Deleting rows in "cor_nom_liste" for all kinds of conflicts (see below bib_noms):
-- - obsolete cd_name + cd_ref association
-- - cd_nom deleted (cd_raison_suppression = 1,2,3)
DELETE FROM taxonomie.cor_nom_liste AS l
WHERE l.id_nom IN (
    SELECT id_nom
    FROM taxonomie.bib_noms
    WHERE cd_nom IN (
        95746, 119151, 119166, 119229, 119362, 119388, 137953,
        85841, 85893, 85914, 85922, 90788, 94956, 95552, 108159, 108225, 108258, 108284, 108288,
        108290, 108324, 108997, 109517, 110477, 116017, 119138, 119168, 119177, 119268, 124829, 141567,
        469860, 607025, 199049, 884045,
        95583, 108148, 109692, 141571, 718789,
        113709, 114383
    )
) ;

-- Deleting rows in "taxonomie.bib_noms" for all kinds of conflicts because:
-- "taxonomie.bib_noms" is only used in SINP for Taxhub INPN medias dowload script.
-- "taxonomie.bib_noms" must be recreated from gn_synthese.synthese if necessary.
DELETE FROM taxonomie.bib_noms
WHERE cd_nom IN (
    95746, 119151, 119166, 119229, 119362, 119388, 137953,
    85841, 85893, 85914, 85922, 90788, 94956, 95552, 108159, 108225, 108258, 108284, 108288,
    108290, 108324, 108997, 109517, 110477, 116017, 119138, 119168, 119177, 119268, 124829, 141567,
    469860, 607025, 199049, 884045,
    95583, 108148, 109692, 141571, 718789,
    113709, 114383
) ;


-- -------------------------------------------------------------------------------------------------
-- Manage Attributs


-- Keep attributs value of destination taxon merged
-- Papaver dubium subsp. dubium [138564] merged in Papaver dubium [112303] :
UPDATE taxonomie.cor_taxon_attribut AS cta1
SET valeur_attribut = cta2.valeur_attribut
FROM taxonomie.cor_taxon_attribut AS cta2
WHERE cta1.cd_ref = 112303
    AND cta1.id_attribut = taxonomie.get_id_attribut_by_name('sinp_description')
    AND cta2.cd_ref = 138564
    AND cta2.id_attribut = taxonomie.get_id_attribut_by_name('sinp_description') ;

-- Plantago coronopus subsp. coronopus [138881] merged in Plantago coronopus [113842]
UPDATE taxonomie.cor_taxon_attribut AS cta1
SET valeur_attribut = cta2.valeur_attribut
FROM taxonomie.cor_taxon_attribut AS cta2
WHERE cta1.cd_ref = 113842
    AND cta1.id_attribut = taxonomie.get_id_attribut_by_name('sinp_ecology')
    AND cta2.cd_ref = 138881
    AND cta2.id_attribut = taxonomie.get_id_attribut_by_name('sinp_ecology') ;

-- Rosmarinus officinalis [118865] merged in Salvia rosmarinus [1027822]
UPDATE taxonomie.cor_taxon_attribut SET cd_ref = 1027822 WHERE cd_ref = 118865 ;

-- Remove useless attributs : cas3 two or more taxons merged
DELETE FROM taxonomie.cor_taxon_attribut WHERE cd_ref IN (
    131360, 131499, 140173, 138564, 97740, 138881, 719191, 126565,
    136979, 137161
) ;


-- -------------------------------------------------------------------------------------------------
-- Manage Media

-- Associate deleted taxons photos to new taxons : cas3 two or more taxons merged

-- Rosmarinus officinalis [118865]
UPDATE taxonomie.t_medias SET cd_ref = 1027822, id_type = 2 WHERE cd_ref = 118865 ;


-- -------------------------------------------------------------------------------------------------
-- Commit if all good
COMMIT;
