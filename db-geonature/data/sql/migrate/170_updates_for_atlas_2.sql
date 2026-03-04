-- Updates for compatibility with Atlas v2.0
-- Required rights: DB OWNER
-- GeoNature database compatibility : v2.9.2+
--
-- Transfert this script on server with Git or this way:
--      rsync -av ./012_* geonat@db-aura-sinp:~/data/db-geonature/data/sql/ --dry-run
-- Use this script this way:
--      psql -h localhost -U geonatadmin -d geonature2db -f ./012_*

BEGIN ;

\echo '----------------------------------------------------------------------------'
\echo 'Insert data in ref_geo.cor_areas:'

DROP TABLE IF EXISTS tmp_area_selected ;

CREATE TEMPORARY TABLE tmp_area_selected AS
    SELECT
        id_area,
        t.type_code,
        geom,
        st_envelope(geom) AS bbox_geom,
        st_buffer(geom, 100) AS buffered_geom
    FROM ref_geo.l_areas AS a
        JOIN ref_geo.bib_areas_types AS t
            ON a.id_type = t.id_type
    WHERE t.type_code IN ('DEP', 'SINP')
        AND "enable" IS TRUE;

CREATE UNIQUE INDEX ON tmp_area_selected
    USING btree (id_area);

CREATE INDEX ON tmp_area_selected
    USING gist (bbox_geom);

CREATE INDEX ON tmp_area_selected
    USING gist (buffered_geom);


TRUNCATE TABLE ref_geo.cor_areas ;


INSERT INTO ref_geo.cor_areas (id_area_group, id_area)
    SELECT *
    FROM (
        -- SINP > DEP
        SELECT
            sinp.id_area AS id_area_group,
            a.id_area
        FROM ref_geo.l_areas AS a
            JOIN tmp_area_selected AS sinp
                ON (
                    sinp.type_code = 'SINP' AND
                    sinp.bbox_geom && a.geom AND
                    st_covers(sinp.buffered_geom, a.geom)
                )
        WHERE a.id_type = ref_geo.get_id_area_type_by_code('DEP')
            AND a."enable" IS TRUE

        UNION

        -- DEP > COM
        SELECT
            dep.id_area AS id_area_group,
            a.id_area
        FROM ref_geo.l_areas AS a
            JOIN tmp_area_selected AS dep
                ON (
                    dep.type_code = 'DEP' AND
                    dep.bbox_geom && a.geom AND
                    st_covers(dep.buffered_geom, a.geom)
                )
        WHERE a.id_type = ref_geo.get_id_area_type_by_code('COM')
            AND a."enable" IS TRUE

        UNION

        -- DEP > PNR
        SELECT
            dep.id_area AS id_area_group,
            a.id_area
        FROM ref_geo.l_areas AS a
            JOIN tmp_area_selected AS dep
                ON (
                    dep.type_code = 'DEP' AND
                    st_intersects(dep.geom, a.geom)
                )
        WHERE a.id_type = ref_geo.get_id_area_type_by_code('PNR')
            AND a."enable" IS TRUE
    ) AS entries(id_area_group, id_area)
    ORDER BY id_area_group, id_area ;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is OK:'
COMMIT ;
