-- Populate bdc_statut_cor_text_area table for SINP AURA.
-- Required rights: DB OWNER
-- GeoNature database compatibility : v2.9.2+
-- Transfert this script on server this way:
-- rsync -av ./004_* geonat@db-aura-sinp:~/data/db-geonature/data/sql/ --dry-run
-- Use this script this way: psql -h localhost -U geonatadmin -d geonature2db \
--      -f ~/data/db-geonature/data/sql/004_*
-- See: https://github.com/PnX-SI/TaxHub/blob/master/apptax/taxonomie/commands/utils.py#L89
BEGIN;


\echo '----------------------------------------------------------------------------'
\echo 'Clean bdc_statut_cor_text_area...'
TRUNCATE TABLE taxonomie.bdc_statut_cor_text_area ;


\echo '----------------------------------------------------------------------------'
\echo 'Populate bdc_statut_cor_text_area...'
WITH regions AS (
    SELECT
        jsonb_array_elements(
            '[
                { "type": "old_r", "metropole": true, "code" : "11", "name" :"Île-de-France", "deps": ["75","77","78","91","92","93","94","95"] },
                { "type": "old_r", "metropole": true, "code" : "21", "name" :"Champagne-Ardenne", "deps": ["08","10","51","52"] },
                { "type": "old_r", "metropole": true, "code" : "22", "name" :"Picardie", "deps": ["02","60","80"] },
                { "type": "old_r", "metropole": true, "code" : "23", "name" :"Haute-Normandie", "deps": ["27", "76"] },
                { "type": "old_r", "metropole": true, "code" : "24", "name" :"Centre", "deps": ["18","28","36","37","41","45"] },
                { "type": "old_r", "metropole": true, "code" : "25", "name" :"Basse-Normandie", "deps": ["14","50","61"] },
                { "type": "old_r", "metropole": true, "code" : "26", "name" :"Bourgogne", "deps": ["21","58","71","89"] },
                { "type": "old_r", "metropole": true, "code" : "31", "name" :"Nord-Pas-de-Calais", "deps": ["59", "62"] },
                { "type": "old_r", "metropole": true, "code" : "41", "name" :"Lorraine", "deps": ["54","55","57","88"] },
                { "type": "old_r", "metropole": true, "code" : "42", "name" :"Alsace", "deps": ["67", "68"] },
                { "type": "old_r", "metropole": true, "code" : "43", "name" :"Franche-Comté", "deps": ["25","39","70","90"] },
                { "type": "old_r", "metropole": true, "code" : "52", "name" :"Pays de la Loire", "deps": ["44","49","53","72","85"] },
                { "type": "old_r", "metropole": true, "code" : "53", "name" :"Bretagne", "deps": ["22","29","35","56"] },
                { "type": "old_r", "metropole": true, "code" : "54", "name" :"Poitou-Charentes", "deps": ["16","17","79","86"] },
                { "type": "old_r", "metropole": true, "code" : "72", "name" :"Aquitaine", "deps": ["24","33","40","47","64"] },
                { "type": "old_r", "metropole": true, "code" : "73", "name" :"Midi-Pyrénées", "deps": ["9","12","31","32","46","65","81","82"] },
                { "type": "old_r", "metropole": true, "code" : "74", "name" :"Limousin", "deps": ["19","23","87"] },
                { "type": "old_r", "metropole": true, "code" : "82", "name" :"Rhône-Alpes", "deps": ["01","07","26","38","42","69","73","74"] },
                { "type": "old_r", "metropole": true, "code" : "83", "name" :"Auvergne", "deps": ["03", "15", "43", "63"] },
                { "type": "old_r", "metropole": true, "code" : "91", "name" :"Languedoc-Roussillon", "deps": ["11","30","34","48","66"] },
                { "type": "old_r", "metropole": true, "code" : "93", "name" :"Provence-Alpes-Côte d’Azur", "deps": ["04", "05", "06", "13", "83", "84"] },
                { "type": "old_r", "metropole": true, "code" : "94", "name" :"Corse", "deps": ["2A", "2B"] },
                { "type": "new_r", "metropole": true, "code" : "11", "name" :"Île-de-France", "deps": ["75","77","78","91","92","93","94","95"] },
                { "type": "new_r", "metropole": true, "code" : "24", "name" :"Centre-Val de Loire", "deps": ["18","28","36","37","41","45"] },
                { "type": "new_r", "metropole": true, "code" : "27", "name" :"Bourgogne-Franche-Comté", "deps": ["21","25","39","58","70","71","89","90"] },
                { "type": "new_r", "metropole": true, "code" : "28", "name" :"Normandie", "deps": ["14","27","50","61","76"] },
                { "type": "new_r", "metropole": true, "code" : "32", "name" :"Hauts-de-France", "deps": ["02", "59", "60", "62", "80"] },
                { "type": "new_r", "metropole": true, "code" : "44", "name" :"Grand Est", "deps": ["08","10","51","52","54","55","57","67","68","88"] },
                { "type": "new_r", "metropole": true, "code" : "52", "name" :"Pays de la Loire", "deps": ["44","49","53","72","85"] },
                { "type": "new_r", "metropole": true, "code" : "53", "name" :"Bretagne", "deps": ["22","29","35","56"] },
                { "type": "new_r", "metropole": true, "code" : "75", "name" :"Nouvelle-Aquitaine", "deps": ["16","17","19","23","24","33","40","47","64","79","86","87"] },
                { "type": "new_r", "metropole": true, "code" : "76", "name" :"Occitanie", "deps": ["09", "11", "12", "30", "31", "32", "34", "46", "48", "65", "66", "81", "82"] },
                { "type": "new_r", "metropole": true, "code" : "84", "name" :"Auvergne-Rhône-Alpes", "deps": ["01", "03", "07", "15", "26", "38", "42", "43", "63", "69", "73", "74"] },
                { "type": "new_r", "metropole": true, "code" : "93", "name" :"Provence-Alpes-Côte d’Azur", "deps": ["04", "05", "06", "13", "83", "84"] },
                { "type": "new_r", "metropole": true, "code" : "94", "name" :"Corse", "deps": ["2A", "2B"] }
            ]' :: jsonb
        ) AS d
),
regions_dep AS (
    SELECT
        jsonb_array_elements_text(d -> 'deps') AS dep,
        d ->> 'code' AS code,
        d ->> 'type' AS TYPE,
        (d->> 'metropole')::boolean AS metropole
    FROM regions
),
regions_dep_areas AS (
    SELECT
        la.id_area,
        d.code,
        d.type,
        d.metropole
    FROM ref_geo.l_areas AS la
        JOIN regions_dep AS d
            ON d.dep = la.area_code
    WHERE id_type = ref_geo.get_id_area_type('DEP')
),
texts AS (
    SELECT -- Si  'ETATFRA'  ou 'EUROPE' ou 'WORLD' insertion de tous les départements
        bst.id_text,
        la.id_area
    FROM taxonomie.bdc_statut_text AS bst
        JOIN regions_dep_areas AS la
            ON  bst.cd_sig IN ('ETATFRA', 'EUROPE', 'WORLD')

    UNION

    SELECT -- Si  'TERFXFR' insertion de tous les départements métropolitains
        bst.id_text,
        la.id_area
    FROM taxonomie.bdc_statut_text AS bst
        JOIN regions_dep_areas AS la
            ON  (
                la.metropole = true
                AND bst.cd_sig = 'TERFXFR'
                AND length(la.code) = 2
            )

    UNION

    SELECT
        DISTINCT -- Si département
        bst.id_text,
        (
            SELECT
                id_area
            FROM
                ref_geo.l_areas
            WHERE
                area_code = REPLACE(cd_sig, 'INSEED', '')
                AND id_type = ref_geo.get_id_area_type('DEP')
        )
    FROM
        taxonomie.bdc_statut_text AS bst
    WHERE
        cd_sig ILIKE 'INSEED%'

    UNION

    SELECT
        DISTINCT -- Si nouvelle région (compatibilité versions anciennes BDC Statut)
        bst.id_text,
        nrs.id_area
    FROM
        taxonomie.bdc_statut_text AS bst
        JOIN regions_dep_areas AS nrs ON (REPLACE(cd_sig, 'INSEENR', '') = nrs.code)
        AND nrs.TYPE = 'new_r'
    WHERE
        cd_sig ILIKE 'INSEENR%'

    UNION

    SELECT
        DISTINCT -- Si ancienne région (mais aussi nouvelle régions dans versions de la BDC Statut récentes)
        bst.id_text,
        ors.id_area
    FROM
        taxonomie.bdc_statut_text AS bst
        JOIN regions_dep_areas AS ors ON (REPLACE(cd_sig, 'INSEER', '') = ors.code)
        AND ors.TYPE IN ('old_r', 'new_r')
    WHERE
        cd_sig ILIKE 'INSEER%'
)
INSERT INTO taxonomie.bdc_statut_cor_text_area (id_text, id_area)
    SELECT
        id_text,
        id_area
    FROM
        texts AS t
    WHERE
        t.id_area IS NOT NULL
    ORDER BY
        t.id_text,
        t.id_area ASC ;


\echo '----------------------------------------------------------------------------'
\echo 'COMMIT if all is OK:'
COMMIT;
