-- OBSERVATIONS DUPLICATES

-- Création d'une vue matéralisée avec pour chaque donnée de la synthèse une signature et l'uuid associé
CREATE MATERIALIZED VIEW IF NOT EXISTS gn_synthese.vm_duplicates AS
    SELECT
        concat(
            replace(cast(date_min AS date)::varchar, '-', ''),
            replace(st_x(the_geom_4326)::varchar, '.', ''),
            replace(st_y(the_geom_4326)::varchar, '.', ''),
            cd_nom
        ) AS signature,
        unique_id_sinp
    FROM gn_synthese.synthese AS s
    WHERE geometrytype(the_geom_4326) = 'POINT'
    ORDER BY signature ;

-- Extraction de toutes les signatures avec au moins deux uuid différents
CREATE OR REPLACE VIEW gn_synthese.v_duplicates_nbr AS
    SELECT
        signature,
        COUNT(unique_id_sinp) AS nbr
    FROM gn_synthese.vm_duplicates
    GROUP BY signature
    HAVING COUNT(unique_id_sinp) >= 2 ;


-- -----------------------------------------------------------------------
-- REQUÊTES UTILES

-- Rafraicheissement, si la vue matérialisée est déjà créée
REFRESH MATERIALIZED VIEW gn_synthese.vm_duplicates ;

-- Observation de la vue matérialisée
SELECT * FROM gn_synthese.vm_duplicates;

-- Observation de la vue
SELECT *
FROM gn_synthese.v_duplicates_nbr;

-- Nb de signatures avec doublon
SELECT COUNT(*)
FROM gn_synthese.v_duplicates_nbr;

-- Nb de doublons
SELECT SUM(nbr) - COUNT(nbr)
FROM gn_synthese.v_duplicates_nbr;

-- Observation des doublons dans la synthèse pour une signature donnée
SELECT *
FROM gn_synthese.synthese
WHERE gn_synthese.synthese.unique_id_sinp IN (
    SELECT unique_id_sinp
	FROM gn_synthese.vm_duplicates
	WHERE signature = '<valeur-de-la-signature>'
)

-- Nombre de doublons par organisme source
SELECT
	id_source,
	CASE
		WHEN id_source IN (1) THEN 'CBNMC'
		WHEN id_source IN (2, 37) THEN 'CBNA'
		WHEN id_source >= 3 AND id_source <= 17 THEN 'LPO'
		WHEN id_source >= 18 AND id_source <= 36 THEN 'FLAVIA'
	END AS organism,
	COUNT(*) AS nbr
FROM gn_synthese.synthese
WHERE gn_synthese.synthese.unique_id_sinp IN (
    SELECT DISTINCT unique_id_sinp
	FROM gn_synthese.vm_duplicates AS vd
		JOIN gn_synthese.v_duplicates_nbr AS vdn
			ON vd.signature = vdn.signature
)
GROUP BY id_source ;

-- -----------------------------------------------------------------------
-- SUPPRESSION DES DOUBLONS
-- Suppression des doublons pour chaque signature
-- Pour 1000 signatures le temps à compter est d'environ 3min

DO language plpgsql
$$
DECLARE
    s VARCHAR;
    u uuid;
    duplicatesNbr INT;
    sourceTable VARCHAR; -- Utile si la table des sources est implémentée
BEGIN
    -- Pour chaque singature il est nécessaire de parcourir chaque uuid sauf le dernier
    FOR s IN SELECT signature FROM v_duplicates_nbr
   	LOOP
        RAISE NOTICE 'Signature --> %', s;
        duplicatesNbr = (SELECT nbr FROM v_duplicates_nbr WHERE signature = s);
        RAISE NOTICE 'Duplicates nbr --> %', duplicatesNbr;
        -- Pour chaque uuid sauf le dernier
        FOR u IN SELECT unique_id_sinp FROM doublons_vm WHERE signature = s LIMIT duplicatesNbr - 1
        LOOP
            RAISE NOTICE 'UUID --> %', u;

            -- Si toutes les tables sources sont implémentées --> décommenter et tester,
            -- IL FAUDRA SUREMENT TROUVER UN MOYEN DE TRANSFORMER LA VARIABLE sourceTable EN NOM DE TABLE

            -- Retrouver la table source de la donnée

            /*
                * sourceTable=(SELECT entity_source_pk_field FROM gn_synthese.t_sources
            WHERE id_source = (SELECT syn.id_source FROM gn_synthese.synthese syn WHERE syn.unique_id_sinp = u));
            -- hist_embrun2016.embrun_2016.gid
            RAISE NOTICE 'Table source --> %', sourceTable;

            IF (sourceTable is null) THEN
                RAISE NOTICE 'Table source nulle';
                -- Supprimer la donnée de la table source (essayer de faire une seule avec la ligne précédente)

            else
                RAISE NOTICE 'Table source non nulle';
                DELETE FROM sourceTable
                WHERE gid=(SELECT syn.entity_source_pk_value FROM gn_synthese.synthese syn WHERE unique_id_sinp = u);

            END IF;
            */

            -- Supprimer la donnée de la synthèse
            DELETE FROM gn_synthese.synthese
            WHERE unique_id_sinp = u;

        END LOOP;
    END LOOP;
END$$
