-- Script to export annual synthesis infos
-- Usage (from local computer): cat ./synthesis_statistics.sql | ssh geonat@pdb-aura-sinp 'export PGPASSWORD="<db-user-pwd>" ; psql -q -h localhost -p 5432 -U gnreader -d geonature2db' > ./$(date +'%F')_synthesis_statistics.csv
-- - <db-user-pwd> : replace with the database user password.
\timing off

COPY (
    WITH prep AS (
        SELECT generate_series(2010, EXTRACT(YEAR FROM CURRENT_DATE)::INTEGER, 1) AS an
    )
    -- Évolution du nombre de données
    SELECT
        'evolution_annuelle' AS nature_donnees,
        prep.an::TEXT AS detail,
        (COUNT(DISTINCT s.id_synthese) FILTER (
            WHERE EXTRACT(YEAR FROM date_min) <= prep.an
        ))::REAL AS nb_data
    FROM gn_synthese.synthese AS s,
        prep
    WHERE s.date_min > '2009-12-31'
    GROUP BY prep.an

    UNION ALL

    -- Part données sensibles
    SELECT
        'part_donnees_sensible',
        NULL::TEXT,
        ((COUNT(id_synthese) FILTER (
            WHERE id_nomenclature_sensitivity <>
                ref_nomenclatures.get_id_nomenclature('SENSIBILITE', '0')
        ))::REAL /
        (COUNT(id_synthese))::REAL) * 100 AS part_donnees_sensible
    FROM gn_synthese.synthese

    UNION ALL

    -- Visualisation de la précision des données
    SELECT
        'synthese_precision',
        ST_GeometryType(the_geom_local) AS type,
        COUNT(id_synthese) AS nb_donnees
    FROM gn_synthese.synthese
    GROUP BY ST_GeometryType(the_geom_local)

    UNION ALL

    -- Répartition de la précision des données
    SELECT 'precision_ligne', 'longueur_min', MIN(ST_Length(the_geom_local))
    FROM gn_synthese.synthese
    WHERE ST_GeometryType(the_geom_local) ILIKE '%line%'

    UNION ALL

    SELECT 'precision_ligne', 'longueur_moy', AVG(ST_Length(the_geom_local))
    FROM gn_synthese.synthese
    WHERE ST_GeometryType(the_geom_local) ILIKE '%line%'

    UNION ALL

    SELECT 'precision_ligne', 'longueur_max', MAX(ST_Length(the_geom_local))
    FROM gn_synthese.synthese
    WHERE ST_GeometryType(the_geom_local) ILIKE '%line%'

    UNION ALL

    SELECT 'precision_ligne', 'surface_min', MIN(ST_Area(the_geom_local))
    FROM gn_synthese.synthese
    WHERE ST_GeometryType(the_geom_local) ILIKE '%polygon'

    UNION ALL

    SELECT 'precision_ligne', 'surface_moy', AVG(ST_Area(the_geom_local))
    FROM gn_synthese.synthese
    WHERE ST_GeometryType(the_geom_local) ILIKE '%polygon'

    UNION ALL

    SELECT 'precision_ligne', 'surface_max', MAX(ST_Area(the_geom_local))
    FROM gn_synthese.synthese
    WHERE ST_GeometryType(the_geom_local) ILIKE '%polygon'

    UNION ALL

    -- Répartition des statuts de validation
    SELECT
        'validation',
        tn.label_fr,
        COUNT(id_synthese) AS nb_data
    FROM gn_synthese.synthese AS s
        JOIN ref_nomenclatures.t_nomenclatures AS tn
            ON tn.id_nomenclature = s.id_nomenclature_valid_status
    GROUP BY tn.label_fr
) TO stdout
WITH (format csv, header, delimiter E'\t');
