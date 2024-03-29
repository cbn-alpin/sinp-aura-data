-- Create index to improve some GeoNature queries
-- Required rights: DB SUPER USER
BEGIN;


\echo '----------------------------------------------------------------------------'
\echo 'Create index on field "observers" for gn_synthese.synthese table.'
CREATE INDEX IF NOT EXISTS i_synthese_observers ON gn_synthese.synthese USING btree (observers) ;

\echo '----------------------------------------------------------------------------'
COMMIT;
