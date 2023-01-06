-- Required rights: DB OWNER
-- GeoNature database compatibility : v2.6.0+
-- Add table with all observations in synthese not linked to areas.
BEGIN;

\echo '-------------------------------------------------------------------------------'
\echo 'Drop "tmp_subdivided_area" table if exists'
DROP TABLE IF EXISTS ref_geo.tmp_subdivided_area ;

\echo '----------------------------------------------------------------------------'
\echo 'Add subdivided SINP territory table'
CREATE TABLE IF NOT EXISTS ref_geo.tmp_subdivided_area AS
    SELECT
        random() AS gid,
        id_type,
        id_area,
        st_subdivide(geom, 255) AS geom
    FROM ref_geo.l_areas
    WHERE id_type IN (
        ref_geo.get_id_area_type_by_code('SINP'),
        ref_geo.get_id_area_type_by_code('DEP'),
        ref_geo.get_id_area_type_by_code('COM')
    );

\echo '----------------------------------------------------------------------------'
\echo 'Create geom index on subdivided SINP territory table'
CREATE INDEX idx_tmp_subdivided_area_geom ON ref_geo.tmp_subdivided_area USING gist(geom);


\echo '-------------------------------------------------------------------------------'
\echo 'Drop "tmp_outside_all" table if exists'
DROP TABLE IF EXISTS gn_synthese.tmp_outside_all ;

\echo '-------------------------------------------------------------------------------'
\echo 'Create "tmp_outside_all" table'
CREATE TABLE IF NOT EXISTS gn_synthese.tmp_outside_all
AS
	SELECT DISTINCT
		s.id_synthese,
		s.unique_id_sinp,
		s.entity_source_pk_value,
        s.id_source,
		s.cd_nom,
		s.nom_cite,
		s.the_geom_local,
		s.date_min,
        s.additional_data
	FROM gn_synthese.synthese s
	WHERE NOT EXISTS(
		SELECT 'X'::text
		FROM ref_geo.tmp_subdivided_area AS c
        WHERE c.id_type = ref_geo.get_id_area_type_by_code('SINP')
            AND public.st_intersects(c.geom, s.the_geom_local)
	)
WITH DATA ;


\echo '-------------------------------------------------------------------------------'
\echo 'Create indexes on tmp_outside_all'
CREATE INDEX tmp_outside_all_id_synthese_idx ON gn_synthese.tmp_outside_all (id_synthese) ;
CREATE INDEX tmp_outside_all_unique_id_sinp_idx ON gn_synthese.tmp_outside_all (unique_id_sinp) ;
CREATE INDEX tmp_outside_all_id_source_idx ON gn_synthese.tmp_outside_all (id_source) ;
CREATE INDEX tmp_outside_all_the_geom_local_idx ON gn_synthese.tmp_outside_all USING gist (the_geom_local) ;


\echo '-------------------------------------------------------------------------------'
\echo 'Drop "tmp_outside_with_geom" table if exists'
DROP TABLE IF EXISTS gn_synthese.tmp_outside_with_geom ;

\echo '-------------------------------------------------------------------------------'
\echo 'Create "tmp_outside_with_geom" table'
CREATE TABLE IF NOT EXISTS gn_synthese.tmp_outside_with_geom
AS
	SELECT DISTINCT
		toa.*
	FROM gn_synthese.tmp_outside_all AS toa
	WHERE toa.the_geom_local IS NOT NULL
        AND NOT EXISTS(
            SELECT 'X'::text
            FROM ref_geo.tmp_subdivided_area AS c
            WHERE c.id_type = ref_geo.get_id_area_type_by_code('SINP')
                AND public.st_intersects(c.geom, toa.the_geom_local)
        )
WITH DATA ;


\echo '-------------------------------------------------------------------------------'
\echo 'Create indexes on tmp_outside_all'
CREATE INDEX tmp_outside_with_geom_id_synthese_idx ON gn_synthese.tmp_outside_with_geom (id_synthese) ;
CREATE INDEX tmp_outside_with_geom_unique_id_sinp_idx ON gn_synthese.tmp_outside_with_geom (unique_id_sinp) ;
CREATE INDEX tmp_outside_with_geom_id_source_idx ON gn_synthese.tmp_outside_with_geom (id_source) ;
CREATE INDEX tmp_outside_with_geom_the_geom_local_idx ON gn_synthese.tmp_outside_with_geom USING gist(the_geom_local) ;


\echo '-------------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
