-- Migrate to GeoNature v2.17
-- Clean all necessary tables before migration in destination db

BEGIN;


\echo '----------------------------------------------------------------------------'
\echo 'Rename modules Synthese'
UPDATE gn_commons.t_modules SET
    module_label = 'Observations',
    module_desc = 'Module Synthèse - Accès aux observations.'
WHERE module_code = 'SYNTHESE' ;


\echo '----------------------------------------------------------------------------'
\echo 'Define modules order'
UPDATE gn_commons.t_modules SET module_order = NULL ;
UPDATE gn_commons.t_modules SET module_order = 1 WHERE module_code = 'GEONATURE' ;
UPDATE gn_commons.t_modules SET module_order = 2 WHERE module_code = 'ADMIN' ;
UPDATE gn_commons.t_modules SET module_order = 3 WHERE module_code = 'PERMREQUESTS' ;
UPDATE gn_commons.t_modules SET module_order = 4 WHERE module_code = 'METADATA' ;
UPDATE gn_commons.t_modules SET module_order = 5 WHERE module_code = 'SYNTHESE' ;
UPDATE gn_commons.t_modules SET module_order = 6 WHERE module_code = 'IMPORT' ;
UPDATE gn_commons.t_modules SET module_order = 7 WHERE module_code = 'EXPORTS' ;
UPDATE gn_commons.t_modules SET module_order = 8 WHERE module_code = 'TAXHUB' ;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is OK:'
COMMIT ;
