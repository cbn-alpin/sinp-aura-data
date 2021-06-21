-- Required rights: DB OWNER
-- GeoNature database compatibility : v2.6.0+
-- Add unique constraints on identifiant and email fields of t_roles table.
-- WARNING: to run this script you must have zero query locking the t_roles table.
-- Use this query to see :
-- SELECT t.schemaname,t.relname,l.locktype,l.page,l.virtualtransaction,l.pid,l.mode,l.granted
-- FROM pg_locks l
--  JOIN pg_stat_all_tables t ON l.relation = t.relid
-- WHERE t.schemaname <> 'utilisateur'::name AND t.schemaname <> 'pg_catalog'::name
-- ORDER BY t.schemaname, t.relname ;
BEGIN;


\echo '-------------------------------------------------------------------------------'
\echo 'Set to NULL "identifiant" field of "t_roles" when value is empty.'
UPDATE utilisateurs.t_roles
SET identifiant = NULL
WHERE identifiant = ''
AND groupe = FALSE ;


\echo '-------------------------------------------------------------------------------'
\echo 'Add unique constraint on "identifiant" field of "t_roles".'
ALTER TABLE utilisateurs.t_roles
    ADD CONSTRAINT unique_identifiant UNIQUE (identifiant) ;


\echo '-------------------------------------------------------------------------------'
\echo 'Set to NULL "email" field of "t_roles" when value is empty.'
UPDATE utilisateurs.t_roles
SET email = NULL
WHERE email = ''
AND groupe = FALSE ;


\echo '-------------------------------------------------------------------------------'
\echo 'Add unique constraint on "email" field of "t_roles".'
ALTER TABLE utilisateurs.t_roles
    ADD CONSTRAINT unique_email UNIQUE (email) ;


\echo '-------------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
