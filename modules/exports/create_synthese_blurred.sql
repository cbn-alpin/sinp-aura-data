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

CREATE MATERIALIZED VIEW gn_exports.synthese_blurred AS
SELECT
    sa.id_synthese,
    sa.id_area,
    st_transform(a.geom, 4326) AS geom_4326,
    t.type_code
FROM gn_synthese.synthese AS s
    JOIN gn_synthese.cor_area_synthese AS sa
        ON s.id_synthese = sa.id_synthese
    JOIN ref_nomenclatures.t_nomenclatures AS sens
        ON s.id_nomenclature_sensitivity = sens.id_nomenclature
    LEFT JOIN ref_nomenclatures.t_nomenclatures AS st
        ON s.id_nomenclature_observation_status = st.id_nomenclature
    JOIN ref_geo.l_areas AS a
        ON sa.id_area = a.id_area
    JOIN ref_geo.bib_areas_types AS t
        ON a.id_type = t.id_type
WHERE s.the_geom_point IS NOT NULL
    AND st.cd_nomenclature = 'Pr'
    AND sens.cd_nomenclature NOT IN ('4', '2.8')
    AND t.type_code IN ('M1', 'M2', 'M5', 'M10', 'M20', 'M50')
    AND gn_exports.is_blurred_area_type(sens.cd_nomenclature, t.type_code) = TRUE
WITH DATA;

CREATE UNIQUE INDEX unique_idx_synthese_blurred
ON gn_exports.synthese_blurred (id_synthese, id_area);

\echo '----------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
