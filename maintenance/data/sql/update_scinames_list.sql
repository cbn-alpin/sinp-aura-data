-- SQL query to update taxonomie.bib_noms table with scientific names of new observations.

INSERT INTO taxonomie.bib_noms (cd_nom, cd_ref)
SELECT DISTINCT
    s.cd_nom,
    t.cd_ref
FROM gn_synthese.synthese AS s
    JOIN taxonomie.taxref AS t
        ON s.cd_nom = t.cd_nom
WHERE NOT s.cd_nom IN (
    SELECT DISTINCT cd_nom
    FROM taxonomie.bib_noms
) ;
