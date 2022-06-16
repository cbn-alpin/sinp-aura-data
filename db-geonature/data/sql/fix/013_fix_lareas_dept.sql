-- Replace departements code by correct number.
-- Required rights: DB OWNER
-- GeoNature database compatibility : v2.6.0+

BEGIN;

\echo '-------------------------------------------------------------------------------'
\echo 'Change string departements codes by number'

UPDATE ref_geo.l_areas SET area_code = '01' WHERE area_code = 'AIN' ;
UPDATE ref_geo.l_areas SET area_code = '03' WHERE area_code = 'ALLIER' ;
UPDATE ref_geo.l_areas SET area_code = '07' WHERE area_code = 'ARDECHE' ;
UPDATE ref_geo.l_areas SET area_code = '15' WHERE area_code = 'CANTAL' ;
UPDATE ref_geo.l_areas SET area_code = '26' WHERE area_code = 'DROME' ;
UPDATE ref_geo.l_areas SET area_code = '43' WHERE area_code = 'HAUTE-LOIRE' ;
UPDATE ref_geo.l_areas SET area_code = '74' WHERE area_code = 'HAUTE-SAVOIE' ;
UPDATE ref_geo.l_areas SET area_code = '38' WHERE area_code = 'ISERE' ;
UPDATE ref_geo.l_areas SET area_code = '42' WHERE area_code = 'LOIRE' ;
UPDATE ref_geo.l_areas SET area_code = '63' WHERE area_code = 'PUY-DE-DOME' ;
UPDATE ref_geo.l_areas SET area_code = '69' WHERE area_code = 'RHONE' ;
UPDATE ref_geo.l_areas SET area_code = '73' WHERE area_code = 'SAVOIE' ;

\echo '-------------------------------------------------------------------------------'
\echo 'COMMIT if all is ok:'
COMMIT;
