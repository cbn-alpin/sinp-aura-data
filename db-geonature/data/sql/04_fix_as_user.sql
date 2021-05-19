-- Droits d'éxecution nécessaire : DB SUPER USER
-- Create index to improve some GeoNature queries
BEGIN;


\echo '----------------------------------------------------------------------------'
\echo 'Create index on field "observers" for gn_synthese.synthese table.'
CREATE INDEX i_synthese_observers ON gn_synthese.synthese USING btree (observers) ;

\echo '----------------------------------------------------------------------------'
COMMIT;
