-- Required rights: DB OWNER
-- GeoNature database compatibility : v2.3.0+
-- Add SINP area
BEGIN;


\echo '----------------------------------------------------------------------------'
\echo 'Insert SINP area type'
INSERT INTO ref_geo.bib_areas_types (
    type_name,
    type_code,
    type_desc,
    ref_name,
    ref_version
)
    SELECT
        'Territoire SINP',
        'SINP',
        'Zone concernée par les données du SINP régional.',
        'IGN admin_express - COG - Compilation des contours des communes',
        2017
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM ref_geo.bib_areas_types AS bat
        WHERE bat.type_code = 'SINP'
    ) ;

\echo '----------------------------------------------------------------------------'
\echo 'Insert SINP area'
INSERT INTO ref_geo.l_areas (
    id_type,
    area_name,
    area_code,
    geom,
    centroid,
    source,
    comment,
    "enable",
    geojson_4326,
    additional_data
)
	SELECT
        ref_geo.get_id_area_type('SINP'),
        area_name,
        area_code,
        geom,
        centroid,
        source,
        comment,
        "enable",
        geojson_4326,
        additional_data
    FROM ref_geo.l_areas
    WHERE id_type = ref_geo.get_id_area_type('REG')
        AND area_code = :'sinpRegCode'
        AND NOT EXISTS (
            SELECT 'X'
            FROM ref_geo.l_areas AS la
            WHERE la.area_code = :'sinpRegCode'
                AND la.id_type = ref_geo.get_id_area_type('SINP')
        ) ;

\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
