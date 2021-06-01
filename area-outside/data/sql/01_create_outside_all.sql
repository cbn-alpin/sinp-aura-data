-- Required rights: DB OWNER
-- GeoNature database compatibility : v2.6.0+
-- Add table with all observations in synthese not linked to areas.
BEGIN;


\echo '-------------------------------------------------------------------------------'
\echo 'Drop "tmp_outside_all" table if exists'
DROP TABLE IF EXISTS gn_synthese.tmp_outside_all ;


\echo '-------------------------------------------------------------------------------'
\echo 'Create "tmp_outside_all" table'
CREATE TABLE gn_synthese.tmp_outside_all
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
		FROM gn_synthese.cor_area_synthese AS cas
		WHERE cas.id_synthese = s.id_synthese
	)
WITH DATA ;


\echo '-------------------------------------------------------------------------------'
\echo 'Create indexes on tmp_outside_all'
CREATE INDEX tmp_outside_all_id_synthese_idx ON gn_synthese.tmp_outside_all (id_synthese) ;
CREATE INDEX tmp_outside_all_unique_id_sinp_idx ON gn_synthese.tmp_outside_all (unique_id_sinp) ;
CREATE INDEX tmp_outside_all_id_source_idx ON gn_synthese.tmp_outside_all (id_source) ;
CREATE INDEX tmp_outside_all_the_geom_local_idx ON gn_synthese.tmp_outside_all USING gist (the_geom_local) ;


\echo '-------------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
