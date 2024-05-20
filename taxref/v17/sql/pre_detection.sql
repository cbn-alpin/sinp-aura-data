-- Mise à jour TaxRef v15 vers v16 pour le SINP AURA
BEGIN;

-- Database change in TaxHub v1.14.0
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
--  Manage TaxRef

-- Change cd_ref in current taxref (v16) to enable check_is_cd_ref on taxonomie.t_medias
-- See https://github.com/PnX-SI/TaxHub/issues/495
UPDATE taxonomie.taxref SET cd_ref = 95557 WHERE cd_nom = 95557 ;
UPDATE taxonomie.taxref SET cd_ref = 112736 WHERE cd_nom = 112736 ;
UPDATE taxonomie.taxref SET cd_ref = 133622 WHERE cd_nom = 133622 ;


-- -------------------------------------------------------------------------------------------------
-- Manage taxonomie.cdnom_disparu.cd_raison_suppression = 1, 2 or 3
-- File: missing_cd_nom_into_database.csv

-- SYNTHESE
-- Set cd_nom to NULL for removing TaxRef cd_nom (cd_raison_suppression = 2 or 3)
UPDATE gn_synthese.synthese
SET cd_nom = NULL
WHERE cd_nom IN (85841, 85893, 85914, 85922, 90788, 94956, 95552, 108159, 108225, 108258, 108284,
108288, 108290, 108324, 108997, 109517, 110477, 116017, 119138, 119168, 119177, 119268, 124829,
141567);

-- Update rows with replacement cd_nom in synthese (cd_raison_suppression = 1)
UPDATE gn_synthese.synthese SET cd_nom = 789254 WHERE cd_nom = 104596 ;
UPDATE gn_synthese.synthese SET cd_nom = 978967 WHERE cd_nom = 109829 ;
UPDATE gn_synthese.synthese SET cd_nom = 113708 WHERE cd_nom = 113709 ;
UPDATE gn_synthese.synthese SET cd_nom = 614970 WHERE cd_nom = 114383 ;


-- -------------------------------------------------------------------------------------------------
-- Manage BIB_NOMS

-- Change non compatible bib_noms rows (old cd_ref) with new TaxRef version
UPDATE taxonomie.bib_noms SET cd_ref = 133622 WHERE cd_nom = 133970 AND cd_ref = 133970 ;
UPDATE taxonomie.bib_noms SET cd_ref = 133622 WHERE cd_nom = 133969 AND cd_ref = 133969 ;

-- Update rows with replacement cd_nom in synthese (cd_raison_suppression = 1)
UPDATE taxonomie.bib_noms SET cd_nom = 789254 WHERE cd_nom = 104596 ;
UPDATE taxonomie.bib_noms SET cd_nom = 978967 WHERE cd_nom = 109829 ;
-- UPDATE taxonomie.bib_noms SET cd_nom = 113708 WHERE cd_nom = 113709 ; -- Already exists => deleting !
-- UPDATE taxonomie.bib_noms SET cd_nom = 614970 WHERE cd_nom = 114383 ; -- Already exists => deleting !


-- Deleting rows in "cor_nom_liste" for all kinds of conflicts (see below bib_noms):
-- - obsolete cd_name + cd_ref association : 88591, 93599, 93653, 133568, 95763, 103278
-- - cd_nom deleted (cd_raison_suppression = 1,2,3) : others
DELETE FROM taxonomie.cor_nom_liste AS l
WHERE l.id_nom IN (
    SELECT id_nom
    FROM taxonomie.bib_noms
    WHERE cd_nom IN (
        85841, 85893, 85914, 85922, 90788, 94956, 95552, 95583, 95746, 108148, 108159, 108225,
        108258, 108284, 108288, 108290, 108324, 108997, 109517, 109692, 110477, 116017, 119138,
        119151, 119166, 119168, 119177, 119229, 119268, 119362, 119388, 124829, 137953, 141567,
        141571, 718789,
        113709, 114383,
        469860, 607025, 199049, 884045
    )
) ;

-- Deleting rows in "taxonomie.bib_noms" for all kinds of conflicts because:
-- "taxonomie.bib_noms" is only used in SINP for Taxhub INPN medias dowload script.
-- "taxonomie.bib_noms" must be recreated from gn_synthese.synthese if necessary.
DELETE FROM taxonomie.bib_noms
WHERE cd_nom IN (
    85841, 85893, 85914, 85922, 90788, 94956, 95552, 95583, 95746, 108148, 108159, 108225,
    108258, 108284, 108288, 108290, 108324, 108997, 109517, 109692, 110477, 116017, 119138,
    119151, 119166, 119168, 119177, 119229, 119268, 119362, 119388, 124829, 137953, 141567,
    141571, 718789,
    113709, 114383,
    469860, 607025, 199049, 884045
) ;


-- -------------------------------------------------------------------------------------------------
-- Manage Attributs

-- Remove useless attributs : cas3 two or more taxons merged
DELETE FROM taxonomie.cor_taxon_attribut WHERE cd_ref IN (
    131360, 131499, 140173, 118865, 138564, 97740, 138881, 719191, 126565,
    80990, 132060, 133970, 133969, 95793, 109091, 138536, 112747, 112745, 141214, 94063, 94066,
    145876, 109084, 111289, 138536, 120700, 718670, 788968, 718671, 91910
) ;

-- -------------------------------------------------------------------------------------------------
-- Manage Media

-- Associate deleted taxons photos to new taxons : cas3 two or more taxons merged
-- Antirrhinum majus subsp. majus [131499]
UPDATE taxonomie.t_medias SET cd_ref = 83058, id_type = 2 WHERE cd_ref = 131499 ;
-- Papaver dubium subsp. dubium [138564]
UPDATE taxonomie.t_medias SET cd_ref = 112303, id_type = 2 WHERE cd_ref = 138564 ;
-- Plantago coronopus subsp. coronopus [138881]
UPDATE taxonomie.t_medias SET cd_ref = 113842, id_type = 2 WHERE cd_ref = 138881 ;
-- Taxus fastigiata [719191]
UPDATE taxonomie.t_medias SET cd_ref = 125816, id_type = 2 WHERE cd_ref = 719191 ;
-- Ajuga reptans [80990]
UPDATE taxonomie.t_medias SET cd_ref = 80988, id_type = 2 WHERE cd_ref = 80990 ;
-- Ballota nigra subsp. foetida [132060]
UPDATE taxonomie.t_medias SET cd_ref = 85502, id_type = 2 WHERE cd_ref = 132060 ;
-- Dryopteris affinis subsp. cambrensis [133970], Dryopteris affinis subsp. borreri [133969]
UPDATE taxonomie.t_medias SET cd_ref = 95557, id_type = 2 WHERE cd_ref IN (133970, 133969) ;
-- Echium vulgare [95793]
UPDATE taxonomie.t_medias SET cd_ref = 95741, id_type = 2 WHERE cd_ref = 95793 ;
-- Persicaria mitis [112747], Persicaria maculosa [112745]
UPDATE taxonomie.t_medias SET cd_ref = 112736, id_type = 2 WHERE cd_ref IN (112747, 112745) ;
-- Silene vulgaris subsp. vulgaris [141214]
UPDATE taxonomie.t_medias SET cd_ref = 123683, id_type = 2 WHERE cd_ref = 141214 ;
-- Cystopteris fragilis [94066], Cystopteris fragilis var. fragilis [145876]
UPDATE taxonomie.t_medias SET cd_ref = 133622, id_type = 2 WHERE cd_ref IN (94066, 145876) ;
-- Myosotis ramosissima [109084]
UPDATE taxonomie.t_medias SET cd_ref = 137934, id_type = 2 WHERE cd_ref = 109084 ;
-- Origanum vulgare [111289]
UPDATE taxonomie.t_medias SET cd_ref = 138444, id_type = 2 WHERE cd_ref = 111289 ;
-- Salvia verbenaca [120700]
UPDATE taxonomie.t_medias SET cd_ref = 140527, id_type = 2 WHERE cd_ref = 120700 ;
-- Clinopodium nepeta subsp. sylvaticum [788968], Clinopodium nepeta [91910]
UPDATE taxonomie.t_medias SET cd_ref = 718332, id_type = 2 WHERE cd_ref IN (788968, 91910) ;


-- -------------------------------------------------------------------------------------------------
-- Commit if all good
COMMIT;
