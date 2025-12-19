-- Copy of ~/data/shared/data/sql/refresh_materialized_view.sql
-- to add the possibility to specifiy a different storage location

-- Enable timing
\timing

-- WARNING : this script is not used for now in imports bash script !
BEGIN;

SET LOCAL temp_tablespaces = 'tmp_data_storage' ;

\echo '----------------------------------------------------------------------------'
\echo 'Refresh "gn_synthese.v_synthese_for_export" materialized view if necessary'
DO $$
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM pg_matviews
            WHERE schemaname = 'gn_synthese' AND matviewname = 'v_synthese_for_export'
        ) IS TRUE THEN
            RAISE NOTICE ' It''s a materialized view => refresh with dependencies concurrently!' ;
            PERFORM public.refresh_recursive_concurrently('v_synthese_for_export') ;
        ELSE
            RAISE NOTICE ' It''s not a materialized view => NO refresh !' ;
        END IF ;
    END
$$ ;


\echo '----------------------------------------------------------------------------'
\echo 'Refresh "gn_profiles" materialized view if necessary'
DO $$
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM information_schema.schemata
            WHERE schema_name = 'gn_profiles'
        ) IS TRUE THEN
            RAISE NOTICE ' Refreshing "gn_profiles" materialized views.' ;
            PERFORM gn_profiles.refresh_profiles();
        ELSE
            RAISE NOTICE ' "gn_profiles" schema not exists !' ;
        END IF ;
    END
$$ ;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is OK:'
COMMIT;
