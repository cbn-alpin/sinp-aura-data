-- Script to refresh Materialized Views of Biodiv'territory.

REFRESH MATERIALIZED VIEW gn_biodivterritory.mv_l_areas_autocomplete;

REFRESH MATERIALIZED VIEW gn_biodivterritory.mv_territory_general_stats;

REFRESH MATERIALIZED VIEW gn_biodivterritory.mv_area_ntile_limit;

REFRESH MATERIALIZED VIEW gn_biodivterritory.mv_general_stats;
