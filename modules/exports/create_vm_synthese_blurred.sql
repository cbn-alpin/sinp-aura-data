-- Create materialized view of synthese data with blurred geometry depending on sensitivity level

-- Enable timing
\timing

BEGIN;

\echo '----------------------------------------------------------------------------'
\echo 'Create function to define if geometry has to be blurred depending on sensitivity level'


CREATE OR REPLACE FUNCTION gn_exports.is_blurred_area_type_by_sensitivity(nomenclaturecode character varying, areatypecode character varying)
RETURNS boolean
LANGUAGE plpgsql
IMMUTABLE
AS $function$
	DECLARE isBlurred boolean;

	BEGIN
		SELECT INTO isBlurred
			CASE
				WHEN ( nomenclatureCode = '1' AND areaTypeCode = 'M5' ) THEN true
				WHEN ( nomenclatureCode = '2' AND areaTypeCode = 'M5' ) THEN true
				WHEN ( nomenclatureCode = '3' AND areaTypeCode = 'M5' ) THEN true
				WHEN ( nomenclatureCode = '2.1' AND areaTypeCode = 'M1' ) THEN true
				WHEN ( nomenclatureCode = '2.2' AND areaTypeCode = 'M2' ) THEN true
				WHEN ( nomenclatureCode = '2.3' AND areaTypeCode = 'M5' ) THEN true
				WHEN ( nomenclatureCode = '2.4' AND areaTypeCode = 'M10' ) THEN true
				WHEN ( nomenclatureCode = '2.5' AND areaTypeCode = 'M20' ) THEN true
				WHEN ( nomenclatureCode = '2.6' AND areaTypeCode = 'M50' ) THEN true
				WHEN ( nomenclatureCode = '2.7' AND areaTypeCode = 'M50' ) THEN true
				ELSE false
			END ;

		RETURN isBlurred ;
	END;
$function$
;

\echo '----------------------------------------------------------------------------'
\echo 'Create function to define if geometry has to be blurred'

CREATE OR REPLACE FUNCTION gn_exports.is_blurred_area_type(sensicode character varying, areatypecode character varying)
RETURNS boolean
LANGUAGE plpgsql
IMMUTABLE
AS $function$
	DECLARE isBlurred boolean;

	BEGIN
		SELECT INTO isBlurred
			CASE
				WHEN sensiCode::NUMERIC >= 1 AND sensiCode::NUMERIC <= 3 THEN
					gn_exports.is_blurred_area_type_by_sensitivity(sensiCode, areaTypeCode)
				ELSE false
			END;

		RETURN isBlurred ;
	END;
$function$
;

\echo '----------------------------------------------------------------------------'
\echo 'Create materialized view with all synthese geometry blurred depending on sensitivity level'

CREATE MATERIALIZED VIEW gn_exports.synthese_blurred
TABLESPACE pg_default
AS SELECT
	sa.id_synthese,
	sa.id_area,
	st_transform(a.geom, 4326) AS geom_4326,
	t.type_code
FROM gn_synthese.synthese s
	JOIN gn_synthese.cor_area_synthese sa
		ON s.id_synthese = sa.id_synthese
	JOIN ref_nomenclatures.t_nomenclatures sens
		ON s.id_nomenclature_sensitivity = sens.id_nomenclature
	LEFT JOIN ref_nomenclatures.t_nomenclatures st
		ON s.id_nomenclature_observation_status = st.id_nomenclature
	JOIN ref_geo.l_areas a
		ON sa.id_area = a.id_area
	JOIN ref_geo.bib_areas_types t
		ON a.id_type = t.id_type
WHERE s.the_geom_point IS NOT NULL
	AND st.cd_nomenclature = 'Pr'
	AND sens.cd_nomenclature NOT IN ('4', '2.8')
	AND t.type_code IN ('M1', 'M2', 'M5', 'M10', 'M20', 'M50')
	AND gn_exports.is_blurred_area_type(sens.cd_nomenclature, t.type_code) = TRUE
WITH DATA;

CREATE UNIQUE INDEX unique_idx_synthese_blurred ON gn_exports.synthese_blurred (id_synthese, id_area);

-- Index on joined columns
CREATE INDEX idx_synthese_id ON gn_synthese.synthese (id_synthese);
CREATE INDEX idx_cor_area_synthese_id ON gn_synthese.cor_area_synthese (id_synthese);
CREATE INDEX idx_nomenclature_sensitivity ON gn_synthese.synthese (id_nomenclature_sensitivity);
CREATE INDEX idx_nomenclature_id ON ref_nomenclatures.t_nomenclatures (id_nomenclature);
CREATE INDEX idx_observation_status ON gn_synthese.synthese (id_nomenclature_observation_status);
CREATE INDEX idx_area_id ON gn_synthese.cor_area_synthese (id_area);
CREATE INDEX idx_l_areas_id ON ref_geo.l_areas (id_area);
CREATE INDEX idx_area_type_id ON ref_geo.l_areas (id_type);
CREATE INDEX idx_bib_areas_types_id ON ref_geo.bib_areas_types (id_type);

-- Index on filtered columns
CREATE INDEX idx_the_geom_point ON gn_synthese.synthese (the_geom_point);
CREATE INDEX idx_cd_nomenclature_st ON ref_nomenclatures.t_nomenclatures (cd_nomenclature);
CREATE INDEX idx_cd_nomenclature_sens ON ref_nomenclatures.t_nomenclatures (cd_nomenclature);
CREATE INDEX idx_type_code ON ref_geo.bib_areas_types (type_code);

-- Index GIST for spatial operations
CREATE INDEX idx_geom_gist ON ref_geo.l_areas USING GIST (geom);


\echo '----------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
