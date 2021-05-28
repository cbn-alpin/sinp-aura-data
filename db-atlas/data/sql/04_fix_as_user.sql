
-- Droits d'éxecution nécessaire : DB OWNER
-- Fix gnatlas database as owner.
-- Use: psql -h localhost -U geonatadmin -d gnatlas -f ./db-atlas/data/sql/04_fix_as_user.sql
BEGIN;


\echo '----------------------------------------------------------------------------'
\echo 'Replace view "synthese.syntheseff"'
-- DROP VIEW IF EXISTS synthese.syntheseff;

CREATE OR REPLACE VIEW synthese.syntheseff AS
WITH obs_data AS (
	SELECT
		s.id_synthese,
		s.cd_nom,
		s.date_min AS dateobs,
		s.observers AS observateurs,
		(s.altitude_min + s.altitude_max) / 2 AS altitude_retenue,
		st_transform(s.the_geom_point, 3857) AS the_geom_point,
		s.count_min AS effectif_total,
		dl.cd_nomenclature::INTEGER AS diffusion_level
	FROM synthese.synthese s
		LEFT JOIN synthese.t_nomenclatures AS dl
			ON (s.id_nomenclature_diffusion_level = dl.id_nomenclature)
		LEFT JOIN synthese.t_nomenclatures AS st
			ON (s.id_nomenclature_observation_status = st.id_nomenclature)
	WHERE ( NOT dl.cd_nomenclature::text = '4'::text OR s.id_nomenclature_diffusion_level IS NULL )
		AND st.cd_nomenclature::text = 'Pr'::text
)
SELECT
	d.id_synthese,
	d.cd_nom,
	d.dateobs,
	d.observateurs,
	d.altitude_retenue,
	d.the_geom_point,
	d.effectif_total,
	c.insee,
	d.diffusion_level
FROM obs_data AS d
	JOIN atlas.l_communes AS c
		ON ( st_intersects(d.the_geom_point, c.the_geom) ) ;


\echo '----------------------------------------------------------------------------'
\echo 'Add missing index to "atlas.vm_observations_mailles" on fields id_observation and geojson_maille'
CREATE UNIQUE INDEX IF NOT EXISTS vm_observations_mailles_id_obs_geojson_idx
    ON atlas.vm_observations_mailles
    USING btree (id_observation, geojson_maille) ;


\echo '----------------------------------------------------------------------------'
\echo 'Replace atlas.vm_communes to improve performance'
DROP MATERIALIZED VIEW IF EXISTS atlas.vm_stats ;
DROP MATERIALIZED VIEW IF EXISTS atlas.vm_communes ;

CREATE MATERIALIZED VIEW atlas.vm_communes
TABLESPACE pg_default
AS
	SELECT DISTINCT
		c.insee,
		c.commune_maj,
		c.the_geom,
		c.commune_geojson
	FROM atlas.l_communes c
		JOIN atlas.t_subdivided_territory t
			ON (st_intersects(t.geom, c.the_geom))
WITH DATA ;

-- View indexes:
CREATE UNIQUE INDEX vm_communes_insee_idx ON atlas.vm_communes USING btree(insee) ;
CREATE INDEX vm_communes_commune_maj_idx ON atlas.vm_communes USING btree(commune_maj) ;
CREATE INDEX index_gist_vm_communes_the_geom ON atlas.vm_communes USING gist(the_geom) ;

CREATE MATERIALIZED VIEW atlas.vm_stats
TABLESPACE pg_default
AS SELECT 'observations'::text AS label,
    count(*) AS result
   FROM atlas.vm_observations
UNION
 SELECT 'municipalities'::text AS label,
    count(*) AS result
   FROM atlas.vm_communes
UNION
 SELECT 'taxons'::text AS label,
    count(DISTINCT vm_taxons.cd_ref) AS result
   FROM atlas.vm_taxons
UNION
 SELECT 'pictures'::text AS label,
    count(DISTINCT m.id_media) AS result
   FROM atlas.vm_medias m
     JOIN atlas.vm_taxons t ON t.cd_ref = m.cd_ref
  WHERE m.id_type = ANY (ARRAY[1, 2])
WITH DATA ;

-- View indexes:
CREATE UNIQUE INDEX vm_stats_label_idx ON atlas.vm_stats USING btree(label) ;

-- Restore permissions
GRANT SELECT ON TABLE atlas.vm_communes TO geonatatlas ;
GRANT SELECT ON TABLE atlas.vm_stats TO geonatatlas ;


\echo '----------------------------------------------------------------------------'
COMMIT;
