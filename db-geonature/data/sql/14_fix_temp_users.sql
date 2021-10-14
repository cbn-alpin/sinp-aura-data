-- Required rights: DB OWNER
-- GeoNature database compatibility : v2.6.0+
-- Increase/Fix utilisateurs.temp_users "organisme" field size.

BEGIN;

\echo '-------------------------------------------------------------------------------'
\echo 'Up to 200 characters "organisme" field in utilisateurs.temp_users table'
ALTER TABLE utilisateurs.temp_users ALTER COLUMN organisme TYPE varchar(200) USING organisme::varchar;

\echo '-------------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
