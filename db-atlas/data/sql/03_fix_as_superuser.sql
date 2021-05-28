-- Droits d'éxecution nécessaire : DB SUPER USER
-- Fix gnatlas database as super user.
-- Use: sudo -u postgres -s psql -d gnatlas -f ./db-atlas/data/sql/03_fix_as_superuser.sql
BEGIN;

\echo '----------------------------------------------------------------------------'
\echo 'Increase fetch size for the foreign tables'
ALTER SERVER geonaturedbserver OPTIONS (ADD fetch_size '100000');

\echo '----------------------------------------------------------------------------'
COMMIT;
