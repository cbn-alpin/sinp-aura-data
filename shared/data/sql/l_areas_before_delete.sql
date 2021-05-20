\echo 'Prepare database before deleting areas into l_areaas'
\echo 'Required rights: db owner'
\echo 'GeoNature database compatibility : v2.3.0+'
BEGIN;


\echo '--------------------------------------------------------------------------------'
\echo 'Disable Foreigns Keys of "l_areas" to speed the deleting'
ALTER TABLE ref_geo.l_areas DROP CONSTRAINT IF EXISTS fk_l_areas_id_type ;
ALTER TABLE ref_geo.li_municipalities DROP CONSTRAINT IF EXISTS fk_li_municipalities_id_area ;
ALTER TABLE ref_geo.li_grids DROP CONSTRAINT IF EXISTS fk_li_grids_id_area ;
ALTER TABLE gn_synthese.synthese DROP CONSTRAINT IF EXISTS fk_synthese_id_area_attachment ;
ALTER TABLE gn_synthese.cor_area_synthese DROP CONSTRAINT IF EXISTS fk_cor_area_synthese_id_area ;
ALTER TABLE gn_monitoring.cor_site_area DROP CONSTRAINT IF EXISTS fk_cor_site_area_id_area ;
ALTER TABLE gn_sensitivity.cor_sensitivity_area DROP CONSTRAINT IF EXISTS fk_cor_sensitivity_area_id_area_fkey ;


\echo '----------------------------------------------------------------------------'
\echo 'Disabling Foreigns Keys of "l_areas" on "cor_area_taxon" table...'
DO $$
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM information_schema.tables
            WHERE table_schema = 'gn_synthese'
                AND table_name = 'cor_area_taxon'
        ) IS TRUE THEN

            RAISE NOTICE ' Drop foreign key between "l_areas" and "cor_area_taxon"' ;
            ALTER TABLE gn_synthese.cor_area_taxon DROP CONSTRAINT IF EXISTS fk_cor_area_taxon_id_area ;

        ELSE
      		RAISE NOTICE ' GeoNature > v2.5.5 => table "gn_synthese.cor_area_taxon" not exists !' ;
        END IF ;
    END
$$ ;

\echo '--------------------------------------------------------------------------------'
\echo 'Drop "l_areas" primary key'
ALTER TABLE ref_geo.l_areas DROP CONSTRAINT IF EXISTS pk_l_areas ;


\echo '--------------------------------------------------------------------------------'
\echo 'Drop "l_areas" indexes not used by deleting'
DROP INDEX IF EXISTS ref_geo.index_l_areas_centroid ;

\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
