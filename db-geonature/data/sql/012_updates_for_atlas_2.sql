-- Updates for compatibility with Atlas v2.0
-- Required rights: DB OWNER
-- GeoNature database compatibility : v2.9.2+
--
-- Transfert this script on server with Git or this way:
--      rsync -av ./012_* geonat@db-aura-sinp:~/data/db-geonature/data/sql/ --dry-run
-- Use this script this way:
--      psql -h localhost -U geonatadmin -d geonature2db -f ./012_*

BEGIN ;

CREATE TABLE IF NOT EXISTS ref_geo.cor_areas (
    id_area_group int4 NULL,
    id_area int4 NULL,
    CONSTRAINT fk_ref_geo_cor_areas_id_area
        FOREIGN KEY (id_area) REFERENCES ref_geo.l_areas(id_area)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_ref_geo_cor_areas_id_area_group
        FOREIGN KEY (id_area_group) REFERENCES ref_geo.l_areas(id_area)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX IF NOT EXISTS ref_geo_cor_areas_id_area ON ref_geo.cor_areas USING btree (id_area);

CREATE INDEX IF NOT EXISTS ref_geo_cor_areas_id_area_group ON ref_geo.cor_areas USING btree (id_area_group);

ALTER TABLE ref_geo.l_areas ADD COLUMN IF NOT EXISTS geom_4326 public.geometry(multipolygon, 4326) NULL;

ALTER TABLE ref_geo.l_areas ADD COLUMN IF NOT EXISTS "description" text NULL;

UPDATE ref_geo.l_areas
SET geom_4326 = st_transform(geom, 4326)
WHERE geom_4326 IS NULL ;

COMMIT ;
