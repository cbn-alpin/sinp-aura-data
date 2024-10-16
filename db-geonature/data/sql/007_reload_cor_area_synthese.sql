-- Re-insert all meshes (M1, M5, M10), departements (DEP), municipalities (COM)
-- and SINP area in gn_synthese.cor_area_synthese table.
--
-- Required rights: DB OWNER
-- GeoNature database compatibility : v2.6.2+
-- Transfert this script on server this way:
-- rsync -av ./reload_cor_area_synthese.sql geonat@db-paca-sinp:~/data/shared/data/sql/ --dry-run
-- Use this script this way: psql -h localhost -U geonatadmin -d geonature2db \
--      -f ~/data/shared/data/sql/reload_cor_area_synthese.sql

\timing

BEGIN;


\echo '----------------------------------------------------------------------------'
\echo 'Create subdivided REG, DEP and COM areas table for faster cor_area_synthese reinsert'

\echo ' Add subdivided REG, DEP and COM areas table'
-- SINP AURA Preprod: 31 735 rows in 29s 352ms
CREATE TEMPORARY TABLE subdivided_areas AS
    SELECT
        random() AS gid,
        a.id_area AS area_id,
        bat.type_code AS code_type,
        a.area_code,
        st_subdivide(a.geom, 250) AS geom
    FROM ref_geo.l_areas AS a
        JOIN ref_geo.bib_areas_types AS bat
            ON bat.id_type = a.id_type
    WHERE a."enable" = TRUE
        AND bat.type_code IN ('REG', 'DEP', 'COM') ;

\echo ' Create index on geom column for subdivided REG, DEP and COM areas table'
CREATE INDEX IF NOT EXISTS idx_subdivided_geom
ON subdivided_areas USING gist(geom);

\echo ' Create index on column id_area for subdivided REG, DEP and COM areas table'
CREATE INDEX IF NOT EXISTS idx_subdivided_area_id
ON subdivided_areas USING btree(area_id) ;


\echo '----------------------------------------------------------------------------'
\echo ' Create table geom_synthese with observations ids group by geom'
-- SINP AURA Preprod (29 million obs): 7 213 407 rows in 03mn 12s 407ms
CREATE TEMPORARY TABLE geom_synthese AS (
    SELECT
        the_geom_local,
        array_agg(id_synthese) AS id_syntheses
    FROM gn_synthese.synthese
    GROUP BY the_geom_local
) ;

\echo ' Create index on geom column for unique geom on synthese table'
-- SINP AURA Preprod: 20s 469ms
CREATE INDEX IF NOT EXISTS idx_geom_synthese_geom
ON geom_synthese USING gist(the_geom_local);


\echo '----------------------------------------------------------------------------'
\echo ' Create table flatten_meshes with meshes M1, M2, M5, M10, M20, M50'
-- SINP AURA Preprod: 72 230 rows in 1mn 45s 846ms
CREATE TEMPORARY TABLE flatten_meshes AS (
    SELECT
        m1.id_area AS id_m1,
        m2.id_area AS id_m2,
        m5.id_area AS id_m5,
        m10.id_area AS id_m10,
        m20.id_area AS id_m20,
        m50.id_area AS id_m50
    FROM (
            SELECT *
            FROM ref_geo.l_areas
            WHERE id_type = ref_geo.get_id_area_type('M1')
        ) AS m1
        LEFT JOIN (
            SELECT *
            FROM ref_geo.l_areas
            WHERE id_type = ref_geo.get_id_area_type('M2')
        ) AS m2
            ON st_contains(m2.geom, m1.centroid)
        LEFT JOIN (
            SELECT *
            FROM ref_geo.l_areas
            WHERE id_type = ref_geo.get_id_area_type('M5')
        ) AS  m5
            ON st_contains(m5.geom, m1.centroid)
        LEFT JOIN (
            SELECT *
            FROM ref_geo.l_areas
            WHERE id_type = ref_geo.get_id_area_type('M10')
        ) AS m10
            ON  st_contains(m10.geom, m5.centroid)
        LEFT JOIN (
            SELECT *
            FROM ref_geo.l_areas
            WHERE id_type = ref_geo.get_id_area_type('M20')
        ) AS m20
            ON st_contains(m20.geom, m10.centroid)
        LEFT JOIN (
            SELECT *
            FROM ref_geo.l_areas
            WHERE id_type = ref_geo.get_id_area_type('M50')
        ) AS m50
            ON st_contains(m50.geom, m20.centroid)
);

\echo ' Create index on column id_m1 for flatten_meshes table'
CREATE INDEX IF NOT EXISTS id_m1_flatten_meshes_idx
ON flatten_meshes USING btree(id_m1);


\echo '----------------------------------------------------------------------------'
\echo 'Delete cor_area_synthese indexes and constraints'
DROP INDEX IF EXISTS gn_synthese.cor_area_synthese_id_area_idx ;

DROP INDEX IF EXISTS gn_synthese.cor_area_synthese_id_synthese_idx ;

ALTER TABLE gn_synthese.cor_area_synthese
DROP CONSTRAINT IF EXISTS fk_cor_area_synthese_id_area ;

ALTER TABLE gn_synthese.cor_area_synthese
DROP CONSTRAINT IF EXISTS fk_cor_area_synthese_id_synthese ;

ALTER TABLE gn_synthese.cor_area_synthese
DROP CONSTRAINT IF EXISTS pk_cor_area_synthese ;


\echo '----------------------------------------------------------------------------'
\echo 'Reinsert all administrative zones (REG, DEP and COM) in cor_area_synthese'

\echo ' Clean Régions, Départements and Communes in table cor_area_synthese'
-- SINP AURA Preprod: 99 824 926 rows in 5mn 04s 582ms
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
-- 13mn23s
WITH synthese_geom_dep AS (
    SELECT DISTINCT
        s.the_geom_local,
        s.id_syntheses,
        a.area_id,
        a.area_code
    FROM geom_synthese AS s
        INNER JOIN subdivided_areas AS a
            ON ( a.code_type = 'DEP' AND st_intersects(s.the_geom_local, a.geom) )
),
area_syntheses AS (
    SELECT DISTINCT
        s.id_syntheses,
        a.area_id
    FROM synthese_geom_dep AS s
        LEFT JOIN subdivided_areas AS a
            ON ( a.code_type = 'COM' AND LEFT(a.area_code, 2) = s.area_code )
    WHERE st_intersects(s.the_geom_local, a.geom )

    UNION ALL

    SELECT
        id_syntheses,
        area_id
    FROM synthese_geom_dep

    UNION ALL

    SELECT DISTINCT
        s.id_syntheses,
        a.id_area AS area_id
    FROM synthese_geom_dep AS s
        LEFT JOIN (
            SELECT id_area
            FROM ref_geo.l_areas
            WHERE id_type = ref_geo.get_id_area_type('REG')
        ) AS a ON TRUE
)
INSERT INTO gn_synthese.cor_area_synthese (id_synthese, id_area)
    SELECT
        unnest(id_syntheses),
        area_id
    FROM area_syntheses ;


\echo '----------------------------------------------------------------------------'
\echo 'Reinsert all meshes (M1, M2, M5, M10, M20, M50) in cor_area_synthese'

\echo ' Clean meshes in table cor_area_synthese'
DELETE FROM gn_synthese.cor_area_synthese
WHERE id_area IN (
    SELECT id_area
    FROM ref_geo.l_areas
    WHERE id_type IN (
        ref_geo.get_id_area_type('M1'), -- 1x1km meshes
        ref_geo.get_id_area_type('M2'), -- 1x1km meshes
        ref_geo.get_id_area_type('M5'), -- 5x5km meshes
        ref_geo.get_id_area_type('M10'), -- 10x10km meshes
        ref_geo.get_id_area_type('M20'), -- 20x20km meshes
        ref_geo.get_id_area_type('M50'), -- 50x50km meshes
    )
) ;

\echo ' Reinsert all meshes'
--
-- 10mn44s
WITH synthese_geom_m1 AS (
    SELECT DISTINCT
        s.id_syntheses,
        a.id_area AS id_m1
    FROM geom_synthese AS s
        INNER JOIN ref_geo.l_areas AS a
            ON (
                a.id_type = ref_geo.get_id_area_type('M1')
                AND st_intersects(s.the_geom_local, a.geom)
            )
),
synthese_geom_meshes AS (
    SELECT
        id_syntheses,
        id_m1 AS id_mesh
    FROM synthese_geom_m1

    UNION

    SELECT
        sgm.id_syntheses,
        fm.id_m2 AS id_mesh
    FROM synthese_geom_m1 AS sgm
        LEFT JOIN flatten_meshes AS fm
            ON sgm.id_m1 = fm.id_m1

    UNION

    SELECT
        sgm.id_syntheses,
        fm.id_m5 AS id_mesh
    FROM synthese_geom_m1 AS sgm
        LEFT JOIN flatten_meshes AS fm
            ON sgm.id_m1 = fm.id_m1

    UNION

    SELECT
        sgm.id_syntheses,
        fm.id_m10 AS id_mesh
    FROM synthese_geom_m1 AS sgm
        LEFT JOIN flatten_meshes AS fm
            ON sgm.id_m1 = fm.id_m1

    UNION

    SELECT
        sgm.id_syntheses,
        fm.id_m20 AS id_mesh
    FROM synthese_geom_m1 AS sgm
        LEFT JOIN flatten_meshes AS fm
            ON sgm.id_m1 = fm.id_m1

    UNION

    SELECT
        sgm.id_syntheses,
        fm.id_m50 AS id_mesh
    FROM synthese_geom_m1 AS sgm
        LEFT JOIN flatten_meshes AS fm
            ON sgm.id_m1 = fm.id_m1
)
INSERT INTO gn_synthese.cor_area_synthese (id_synthese, id_area)
    SELECT
        UNNEST(id_syntheses) AS id_synthese,
        id_mesh
    FROM synthese_geom_meshes ;


\echo '----------------------------------------------------------------------------'
\echo 'Reinsert all observations link to SINP territory in cor_area_synthese'

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
-- 47s 946ms
WITH sinp AS (
    SELECT id_area
    FROM ref_geo.l_areas
    WHERE id_type = ref_geo.get_id_area_type('SINP') -- SINP area
    LIMIT 1
)
INSERT INTO gn_synthese.cor_area_synthese (id_synthese, id_area)
    SELECT
        s.id_synthese,
        sinp.id_area
    FROM gn_synthese.synthese AS s, sinp ;


\echo '----------------------------------------------------------------------------'
\echo 'Recreate cor_area_synthese indexes and constraints'
ALTER TABLE gn_synthese.cor_area_synthese
ADD CONSTRAINT pk_cor_area_synthese PRIMARY KEY (id_synthese, id_area) ;

ALTER TABLE gn_synthese.cor_area_synthese
ADD CONSTRAINT fk_cor_area_synthese_id_area
FOREIGN KEY (id_area) REFERENCES ref_geo.l_areas(id_area)
ON DELETE CASCADE ON UPDATE CASCADE ;

ALTER TABLE gn_synthese.cor_area_synthese
ADD CONSTRAINT fk_cor_area_synthese_id_synthese
FOREIGN KEY (id_synthese) REFERENCES gn_synthese.synthese(id_synthese)
ON DELETE CASCADE ON UPDATE CASCADE ;

CREATE INDEX cor_area_synthese_id_area_idx
ON gn_synthese.cor_area_synthese USING btree (id_area);

CREATE INDEX cor_area_synthese_id_synthese_idx
ON gn_synthese.cor_area_synthese USING btree (id_synthese);


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is OK:'
COMMIT;
