-- Droits d'éxecution nécessaire : DB SUPER USER
-- Change tables wrong owner
BEGIN;

\echo '----------------------------------------------------------------------------'
\echo 'Restore owner of GeoNature database (need after backup restore)'
ALTER DATABASE geonature2db OWNER TO geonatadmin;

\echo '----------------------------------------------------------------------------'
\echo 'Fix owner of table taxonomie.taxref_bdc_statut'
ALTER TABLE taxonomie.taxref_bdc_statut OWNER TO geonatadmin;

\echo '----------------------------------------------------------------------------'
\echo 'Fix owner of table taxonomie.taxref_bdc_statut_type'
ALTER TABLE taxonomie.taxref_bdc_statut_type OWNER TO geonatadmin;

\echo '----------------------------------------------------------------------------'
COMMIT;
