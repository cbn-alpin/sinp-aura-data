-- Updates for compatibility with Atlas v2.0
-- Required rights: DB OWNER
-- GeoNature database compatibility : v2.9.2+
--
-- Transfert this script on server with Git or this way:
--      rsync -av ./012_* geonat@db-aura-sinp:~/data/db-geonature/data/sql/ --dry-run
-- Use this script this way:
--      psql -h localhost -U geonatadmin -d geonature2db -f ./012_*

BEGIN ;

ALTER TABLE ref_geo.l_areas
    ADD COLUMN IF NOT EXISTS geom_4326 public.geometry(multipolygon, 4326) OPTIONS(column_name 'geom_4326') NULL,
	ADD COLUMN IF NOT EXISTS description text OPTIONS(column_name 'description') NULL ;

UPDATE ref_geo.l_areas
SET geom_4326 = st_transform(geom, 4326)
WHERE geom_4326 IS NULL ;

COMMIT ;
