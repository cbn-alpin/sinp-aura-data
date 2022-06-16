-- Delete sources unused after GN2PG use.
-- Required rights: DB OWNER
-- GeoNature database compatibility : v2.6.0+

BEGIN;

\echo '-------------------------------------------------------------------------------'
\echo 'Remove unused sources'

WITH used_sources AS (
    SELECT DISTINCT id_source
    FROM gn_synthese.synthese
)
DELETE FROM gn_synthese.t_sources WHERE id_source NOT IN (SELECT id_source FROM used_sources) ;

\echo '-------------------------------------------------------------------------------'
\echo 'Complete GN2PG sources'

UPDATE gn_synthese.t_sources SET
    desc_source = 'Data issues de l''importation via GN2PG depuis la base LPO Auvergne-Rhône-Alpes.',
    entity_source_pk_field = 'id_synthese',
    url_source = 'https://orb.lpo-aura.org/#/synthese/occurrence/'
WHERE id_source = gn_synthese.get_id_source_by_name('lpo') ;

UPDATE gn_synthese.t_sources SET
    desc_source = 'Data issues de l''importation via GN2PG depuis la base du Pôle Invertébrés.',
    entity_source_pk_field = 'id_synthese',
    url_source = 'https://donnees.pole-invertebres.fr/#/synthese/occurrence/'
WHERE id_source = gn_synthese.get_id_source_by_name('flavia') ;

\echo '-------------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
