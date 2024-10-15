-- Re-insert all meshes (M1, M5, M10), departements (DEP), municipalities (COM)
-- and SINP area in gn_synthese.cor_area_synthese table.
--
-- Required rights: DB OWNER
-- GeoNature database compatibility : v2.6.2+
-- Transfert this script on server this way:
-- rsync -av ./reload_cor_area_synthese.sql geonat@db-paca-sinp:~/data/shared/data/sql/ --dry-run
-- Use this script this way: psql -h localhost -U geonatadmin -d geonature2db \
--      -f ~/data/shared/data/sql/reload_cor_area_synthese.sql
BEGIN;


\echo '----------------------------------------------------------------------------'
\echo 'Disable triggers depending of GeoNature version'
DO $$
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM pg_trigger
            WHERE tgname = 'tri_maj_cor_area_taxon'
        ) IS TRUE THEN
            RAISE NOTICE ' For GeoNature < v2.6.0, disable trigger "tri_maj_cor_area_taxon"' ;
            ALTER TABLE gn_synthese.cor_area_synthese DISABLE TRIGGER tri_maj_cor_area_taxon ;
        ELSE
      		RAISE NOTICE ' GeoNature > v2.5.5 => trigger "tri_maj_cor_area_taxon" not exists !' ;
        END IF ;

        IF EXISTS (
            SELECT 1
            FROM pg_trigger
            WHERE tgname = 'tri_update_cor_area_taxon_update_cd_nom'
        ) IS TRUE THEN
            RAISE NOTICE ' For GeoNature < v2.6.0, disable trigger "tri_update_cor_area_taxon_update_cd_nom"' ;
            ALTER TABLE gn_synthese.cor_area_synthese DISABLE TRIGGER tri_update_cor_area_taxon_update_cd_nom ;
        ELSE
      		RAISE NOTICE ' GeoNature > v2.5.5 => trigger "tri_update_cor_area_taxon_update_cd_nom" not exists !' ;
        END IF ;
    END
$$ ;


\echo '----------------------------------------------------------------------------'
\echo 'Create subdivided REG, DEP and COM areas table for faster cor_area_synthese reinsert'

\echo ' Remove subdivided REG, DEP and COM areas table if necessary'
DROP TABLE IF EXISTS ref_geo.tmp_subdivided_areas ;

\echo ' Remove geom index on subdivided REG, DEP and COM areas table'
DROP INDEX IF EXISTS ref_geo.idx_tmp_subdivided_areas ;

\echo ' Add subdivided REG, DEP and COM areas table'
CREATE TABLE ref_geo.tmp_subdivided_areas AS
    SELECT
        random() AS gid,
        a.id_area AS area_id,
        a.id_type,
        a.area_code,
        st_subdivide(a.geom, 250) AS geom
    FROM ref_geo.l_areas AS a
    WHERE a."enable" = TRUE
        AND a.id_type IN (
            ref_geo.get_id_area_type('REG'), -- Régions
            ref_geo.get_id_area_type('DEP'), -- Départements
            ref_geo.get_id_area_type('COM') -- Communes
        ) ;

\echo ' Create index on geom column for subdivided REG, DEP and COM areas table'
CREATE INDEX IF NOT EXISTS idx_tmp_subdivided_geom ON ref_geo.tmp_subdivided_areas USING gist (geom);

\echo ' Create index on column id_area for subdivided REG, DEP and COM areas table'
CREATE INDEX IF NOT EXISTS idx_tmp_subdivided_area_id ON ref_geo.tmp_subdivided_areas USING btree(area_id) ;

\echo ' Create unique geom on synthese table'

CREATE TABLE gn_synthese.geom_synthese AS (
	SELECT 
		s.the_geom_local,
		array_agg(id_synthese) AS id_syntheses 
	FROM gn_synthese.synthese AS s 
	GROUP BY s.the_geom_local
) ;

\echo ' Create index on geom column for unique geom on synthese table'
CREATE INDEX IF NOT EXISTS idx_geom_synthese_geom ON gn_synthese.geom_synthese USING gist (the_geom_local);


\echo '----------------------------------------------------------------------------'
\echo 'Reinsert all data in cor_area_synthese'

-- TRUNCATE TABLE cor_area_synthese ;
-- TO AVOID TRUNCATE : add condition on id_source or id_dataset to reduce synthese table entries in below inserts

\echo ' Clean Régions, Départements and Communes in table cor_area_synthese'
SET session_replication_role = REPLICA;
DELETE FROM gn_synthese.cor_area_synthese
WHERE id_area IN (
    SELECT id_area
    FROM ref_geo.l_areas
    WHERE id_type IN (
        ref_geo.get_id_area_type('REG'), -- Régions
        ref_geo.get_id_area_type('DEP'), -- Départements
        ref_geo.get_id_area_type('COM') -- Communes
    )
) ;

\echo ' Reinsert Régions, Départements and Communes'
INSERT INTO gn_synthese.cor_area_synthese (id_synthese, id_area)
WITH synthese_geom_dep AS (
	SELECT DISTINCT 
		s.the_geom_local,
		s.id_syntheses,
		a.area_id,
		a.area_code
	FROM gn_synthese.geom_synthese s
		INNER JOIN ref_geo.tmp_subdivided_areas a 
			ON a.id_type IN (
	            ref_geo.get_id_area_type('REG'), -- Régions
	            ref_geo.get_id_area_type('DEP') -- Départements
	        	)  AND st_intersects(s.the_geom_local, a.geom )
	 ),
 
area_syntheses AS (
	SELECT DISTINCT 
		s.id_syntheses,
		a.area_id
	FROM synthese_geom_dep  AS s
		LEFT JOIN ref_geo.tmp_subdivided_areas AS a 
			ON a.id_type =ref_geo.get_id_area_type('COM') 
				AND LEFT(a.area_code,2) = s.area_code 
	WHERE st_intersects(s.the_geom_local, a.geom )
	UNION ALL 
 	SELECT 
 		s.id_syntheses, 
 		s.area_id
	FROM synthese_geom_dep s
)
   
	SELECT  
    	unnest(id_syntheses),
    	s.area_id 
	FROM area_syntheses AS s;
	
\echo ' Create table maille_pyramide with meshes M1, M5, M10 '	
CREATE TABLE ref_geo.maille_pyramide AS ( 
 	SELECT  m1.id_area id_maille1,
 			m5.id_area id_maille5,
 			m10.id_area id_maille10
	FROM (
		SELECT * 
		FROM ref_geo.l_areas 
		WHERE id_type =ref_geo.get_id_area_type('M1')
		) AS m1  
	LEFT JOIN (
		SELECT * 
		FROM ref_geo.l_areas 
		WHERE id_type =ref_geo.get_id_area_type('M5')
		) AS  m5
			ON st_contains(m5.geom, m1.centroid )
	LEFT JOIN (
		SELECT * 
		FROM ref_geo.l_areas 
		WHERE id_type =ref_geo.get_id_area_type('M10')
		) AS m10
			 ON  st_contains(m10.geom, m5.centroid)
) ;

\echo ' Create index on column id_maille1 for maille_pyramide table'			 
CREATE INDEX IF NOT EXISTS id_maille1_maille_pyramide_idx ON  ref_geo.maille_pyramide USING btree (id_maille1);


\echo ' Clean Meshes (M1, M5, M10) in table cor_area_synthese'
DELETE FROM gn_synthese.cor_area_synthese
WHERE id_area IN (
    SELECT id_area
    FROM ref_geo.l_areas
    WHERE id_type IN (
        ref_geo.get_id_area_type('M1'), -- 1x1km meshes
        ref_geo.get_id_area_type('M5'), -- 5x5km meshes
        ref_geo.get_id_area_type('M10') -- 10x10km meshes
    )
) ;

\echo ' Reinsert for meshes'

INSERT INTO gn_synthese.cor_area_synthese (id_synthese, id_area)
WITH synthese_geom_maille1 AS (
	SELECT DISTINCT 
		s.the_geom_local,
		s.id_syntheses, 
		a.id_area AS id_maille1,
		a.area_code
	FROM gn_synthese.geom_synthese AS s
		INNER JOIN ref_geo.l_areas AS a 
			ON a.id_type = ref_geo.get_id_area_type('M1')
           		AND st_intersects(s.the_geom_local, a.geom )
),
           
synthese_geom_maille AS (
	SELECT 
		id_syntheses,
		mp.id_maille5 AS id_maille 
 	FROM synthese_geom_maille1 AS sm1
 		LEFT JOIN ref_geo.maille_pyramide AS mp 
 			ON sm1.id_maille1 = mp.id_maille1
	UNION 
	SELECT 
		id_syntheses,
		mp.id_maille10 AS id_maille
 	FROM synthese_geom_maille1 AS sm1
 		LEFT JOIN ref_geo.maille_pyramide AS mp 
 			ON sm1.id_maille1 = mp.id_maille1
	UNION 
	SELECT 
		id_syntheses,
		id_maille1 AS id_maille 
 	FROM synthese_geom_maille1 AS sm1
)

SELECT 
	UNNEST(s.id_syntheses) AS id_synthese,
	id_maille 
FROM synthese_geom_maille AS s;

\echo ' Clean SINP area in table cor_area_synthese'
WITH sinp AS (
    SELECT id_area
    FROM ref_geo.l_areas
    WHERE id_type = ref_geo.get_id_area_type('SINP')
    LIMIT 1
)
DELETE FROM gn_synthese.cor_area_synthese
WHERE id_area IN (
    SELECT id_area
    FROM sinp
) ;

\echo ' Reinsert all observations in cor_area_synthese link to SINP area'
INSERT INTO gn_synthese.cor_area_synthese (id_synthese, id_area)
    WITH sinp AS (
        SELECT id_area
        FROM ref_geo.l_areas
        WHERE id_type = ref_geo.get_id_area_type('SINP') -- SINP area
        LIMIT 1
    )
    SELECT
        s.id_synthese,
        sinp.id_area
    FROM gn_synthese.synthese AS s, sinp ;
-- ON CONFLICT ON CONSTRAINT pk_cor_area_synthese DO NOTHING;

SET session_replication_role = DEFAULT;
\echo ' Drop temporary table'
DROP TABLE gn_synthese.geom_synthese; 
DROP TABLE ref_geo.maille_pyramide;

\echo '-------------------------------------------------------------------------------'
\echo 'For GeoNature < v2.6.0, replay actions on table "cor_area_taxon" (play after cor_area_synthese trigger)'
DO $$
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM information_schema.tables
            WHERE table_schema = 'gn_synthese'
                AND table_name = 'cor_area_taxon'
        ) IS TRUE THEN
            RAISE NOTICE ' Clean table cor_area_taxon' ;
            TRUNCATE TABLE cor_area_taxon ;
            -- TO AVOID TRUNCATE : add condition on id_source or id_dataset to reduce synthese table entries in below insert

            RAISE NOTICE ' Reinsert all data in cor_area_taxon' ;
            INSERT INTO cor_area_taxon (id_area, cd_nom, last_date, nb_obs)
                SELECT cor.id_area, s.cd_nom, MAX(s.date_min) AS last_date, COUNT(s.id_synthese) AS nb_obs
                FROM cor_area_synthese AS cor
                    JOIN synthese AS s
                        ON (s.id_synthese = cor.id_synthese)
                GROUP BY cor.id_area, s.cd_nom ;
        ELSE
      		RAISE NOTICE ' GeoNature > v2.5.5 => table "gn_synthese.cor_area_taxon" not exists !' ;
        END IF ;
    END
$$ ;


\echo '----------------------------------------------------------------------------'
\echo 'Enable triggers depending of GeoNature version'
DO $$
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM pg_trigger
            WHERE tgname = 'tri_maj_cor_area_taxon'
        ) IS TRUE THEN
            RAISE NOTICE ' For GeoNature < v2.6.0, enable "tri_maj_cor_area_taxon" trigger' ;
            ALTER TABLE cor_area_synthese ENABLE TRIGGER tri_maj_cor_area_taxon ;
        ELSE
      		RAISE NOTICE ' GeoNature > v2.5.5 => trigger "tri_maj_cor_area_taxon" not exists !' ;
        END IF ;

        IF EXISTS (
            SELECT 1
            FROM pg_trigger
            WHERE tgname = 'tri_update_cor_area_taxon_update_cd_nom'
        ) IS TRUE THEN
            RAISE NOTICE ' For GeoNature < v2.6.0, enable trigger "tri_update_cor_area_taxon_update_cd_nom"' ;
            ALTER TABLE cor_area_synthese ENABLE TRIGGER tri_update_cor_area_taxon_update_cd_nom ;
        ELSE
      		RAISE NOTICE ' GeoNature > v2.5.5 => trigger "tri_update_cor_area_taxon_update_cd_nom" not exists !' ;
        END IF ;
    END
$$ ;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is OK:'
COMMIT;
