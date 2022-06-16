-- Fix gnatlas database materialized views owner.
-- Droits d'éxecution nécessaire : DB SUPER USER
-- Use: sudo -u postgres -s psql -d gnatlas -f ~/data/db-atlas/data/sql/06_fix_gnatlas_owner.sql
BEGIN;

\echo '----------------------------------------------------------------------------'
\echo 'Add rights to geonatatlas on materialized views'
GRANT SELECT ON TABLE atlas.vm_taxon_attribute TO geonatatlas;
GRANT SELECT ON TABLE atlas.vm_subdivided_area TO geonatatlas;
GRANT SELECT ON TABLE atlas.t_layer_territoire TO geonatatlas;
GRANT SELECT ON TABLE atlas.l_communes TO geonatatlas;
GRANT SELECT ON TABLE synthese.vm_cor_synthese_area TO geonatatlas;


\echo '----------------------------------------------------------------------------'
COMMIT;
