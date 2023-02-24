-- Queries to extract :
-- * request count by departements
-- * accepted request count by departements

WITH requests AS (
	SELECT id_request, unnest(string_to_array(geographic_filter,','))::integer AS id_area, processed_state
	FROM gn_permissions.t_requests
	WHERE meta_create_date >= '2022-01-01 00:00:00'
		AND meta_create_date < '2023-01-01 00:00:00'
),
requests_by_dep AS (
	SELECT a.area_code, rd.id_request
	FROM ref_geo.l_areas AS a JOIN LATERAL (
			SELECT r.id_request
			FROM requests AS r
				JOIN ref_geo.l_areas AS la
					ON r.id_area = la.id_area
			WHERE (la.id_type = ref_geo.get_id_area_type('COM') AND substring(la.area_code from 1 for 2) = a.area_code)
				OR (la.id_type = ref_geo.get_id_area_type('DEP') AND la.area_code = a.area_code)
				OR la.id_type = ref_geo.get_id_area_type('SINP')
			GROUP BY r.id_request
		) AS rd
			ON true
	WHERE a.id_type = ref_geo.get_id_area_type('DEP')
)
SELECT area_code AS departement_code, COUNT(id_request) AS requests_count
FROM requests_by_dep
GROUP BY area_code ;


WITH requests AS (
	SELECT id_request, unnest(string_to_array(geographic_filter,','))::integer AS id_area, processed_state
	FROM gn_permissions.t_requests
	WHERE meta_create_date >= '2022-01-01 00:00:00'
		AND meta_create_date < '2023-01-01 00:00:00'
		AND processed_state = 'accepted'
),
requests_by_dep AS (
	SELECT a.area_code, rd.id_request
	FROM ref_geo.l_areas AS a JOIN LATERAL (
			SELECT r.id_request
			FROM requests AS r
				JOIN ref_geo.l_areas AS la
					ON r.id_area = la.id_area
			WHERE (la.id_type = ref_geo.get_id_area_type('COM') AND substring(la.area_code from 1 for 2) = a.area_code)
				OR (la.id_type = ref_geo.get_id_area_type('DEP') AND la.area_code = a.area_code)
				OR la.id_type = ref_geo.get_id_area_type('SINP')
			GROUP BY r.id_request
		) AS rd
			ON true
	WHERE a.id_type = ref_geo.get_id_area_type('DEP')
)
SELECT area_code AS departement_code, COUNT(id_request) AS accepted_requests_count
FROM requests_by_dep
GROUP BY area_code ;
