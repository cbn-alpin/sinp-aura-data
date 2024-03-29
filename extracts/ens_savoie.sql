-- Query to extracts data for Savoie ENS
-- Usage (from local computer): cat ./ens_savoie.sql | ssh <user>@<ip-server> 'export PGPASSWORD="<db-user-password>" ; psql -h localhost -p <db-port> -U <db-user> -d <db-name>' > ./$(date +'%F')_extracts.csv
-- The CSV file should contain 1,053,704 lines.
COPY (
    WITH PLANTAE_SENSITIVE_TAXONS AS (
        SELECT DISTINCT t2.cd_nom 
		FROM taxonomie.taxref AS t1
			JOIN taxonomie.taxref AS t2
				ON t1.cd_ref = t2.cd_ref
		WHERE t1.cd_nom IN (81522, 82287, 82498, 82509, 83973, 83974, 84053, 84330, 143985, 84476, 131826, 84554, 84572, 131929, 85628, 86122, 86182, 86186,
			86189, 86199, 87417, 87620, 87897, 87963, 88077, 88360, 88404, 88426, 526279, 88562, 88576, 88932, 132840, 718327, 89195, 90046,
			612609, 91727, 91790, 92331, 93112, 619231, 133766, 133773, 133791, 95323, 95439, 95561, 95601, 611166, 521628, 521629, 96443,
			717179, 98060, 99193, 100024, 100273, 135088, 100616, 101223, 101315, 102451, 102794, 717776, 103020, 103056, 103308, 103383,
			612499, 103501, 103841, 610647, 610656, 137171, 137229, 106260, 106353, 106446, 107013, 719047, 107024, 610911, 107509, 108044,
			108484, 610593, 109735, 110068, 138235, 138282, 138536, 717390, 138817, 115302, 115395, 115458, 115563, 115894, 117668, 118192,
			121076, 121096, 121124, 121184, 122112, 122508, 123082, 123679, 124699, 124775, 125519, 717603, 126070, 127546, 127918, 127921,
			127928, 127942, 127943, 127945, 127950, 611363, 611365, 129275, 129557, 129643, 129660, 130128)
    ),
    PLANTAE_SENSITIVE_OBS_IN_SAVOIE AS (
        SELECT s.id_synthese
        FROM gn_synthese.synthese s
            JOIN gn_synthese.cor_area_synthese AS a
                ON s.id_synthese = a.id_synthese
        WHERE a.id_area = (SELECT id_area FROM ref_geo.l_areas WHERE area_code = 'SAVOIE')
            AND s.cd_nom IN (SELECT cd_nom FROM PLANTAE_SENSITIVE_TAXONS)
    ),
    NON_PLANTAE_SENSITIVE_OBS_IN_SAVOIE AS (
        SELECT s.id_synthese
        FROM gn_synthese.synthese s
            JOIN gn_synthese.cor_area_synthese AS cas
                ON s.id_synthese = cas.id_synthese
        WHERE cas.id_area = (SELECT id_area FROM ref_geo.l_areas WHERE area_code = 'SAVOIE')
            AND s.id_synthese NOT IN (SELECT id_synthese FROM PLANTAE_SENSITIVE_OBS_IN_SAVOIE)
            AND s.id_nomenclature_sensitivity IS NOT NULL
            AND s.id_nomenclature_sensitivity != ref_nomenclatures.get_id_nomenclature('SENSIBILITE', '0') -- Non sensible - Diffusion précise
            AND s.id_nomenclature_sensitivity != ref_nomenclatures.get_id_nomenclature('SENSIBILITE', '4') -- Sensible - Aucune diffusion - NE PAS DIFFUSER !
    ),
    ALL_TAXA_NON_SENSITIVE_OBS_IN_SAVOIE AS (
        SELECT s.id_synthese
        FROM gn_synthese.synthese s
            JOIN gn_synthese.cor_area_synthese AS cas
                ON s.id_synthese = cas.id_synthese
        WHERE cas.id_area = (SELECT id_area FROM ref_geo.l_areas WHERE area_code = 'SAVOIE')
            AND (
                s.id_nomenclature_sensitivity IS NULL
                OR s.id_nomenclature_sensitivity = ref_nomenclatures.get_id_nomenclature('SENSIBILITE', '0') -- Non sensible - Diffusion précise
            )
    ),
    OBS_IN_SAVOIE AS (
        -- PLANTAE SENSITIVE OBS IN SAVOIE
        SELECT
            s.id_synthese,
            'Maille 5km' AS niveau_precision,
            l.geom AS geom
        FROM gn_synthese.synthese AS s
            JOIN gn_synthese.cor_area_synthese AS b
                ON s.id_synthese = b.id_synthese
            JOIN ref_geo.l_areas AS l
                ON b.id_area = l.id_area
        WHERE l.id_type = ref_geo.get_id_area_type('M5')
            AND s.id_synthese IN (SELECT id_synthese FROM PLANTAE_SENSITIVE_OBS_IN_SAVOIE)

        UNION

        -- NON PLANTAE TAXA SENSITIVE OBS IN SAVOIE
        SELECT
            s.id_synthese,
            'Maille 5km' AS niveau_precision,
            l.geom AS geom
        FROM gn_synthese.synthese AS s
            JOIN gn_synthese.cor_area_synthese AS b
                ON s.id_synthese = b.id_synthese
            JOIN ref_geo.l_areas AS l
                ON b.id_area = l.id_area
        WHERE l.id_type = ref_geo.get_id_area_type('M5')
            AND s.id_synthese IN (SELECT id_synthese FROM NON_PLANTAE_SENSITIVE_OBS_IN_SAVOIE)

        UNION

        -- ALL TAXA NON SENSITIVE OBS IN SAVOIE
        SELECT
            s.id_synthese,
            'Précise' AS niveau_precision,
            s.the_geom_local AS geom
        FROM gn_synthese.synthese AS s
        WHERE s.id_synthese IN (SELECT id_synthese FROM ALL_TAXA_NON_SENSITIVE_OBS_IN_SAVOIE)
    )
    SELECT
        s.unique_id_sinp AS uuid_perm_sinp,
        s.unique_id_sinp_grp AS uuid_perm_grp_sinp,
        c.unique_acquisition_framework_id AS ca_uuid,
        c.acquisition_framework_name AS ca_nom,
        j.unique_dataset_id AS jdd_uuid,
        j.dataset_name AS jdd_nom,
        n.label_default AS niveau_validation,
        s."validator" AS validateur,
        s.observers AS observateurs,
        t.cd_ref,
        t.nom_valide,
        s.count_min AS nombre_min,
        s.count_max AS nombre_max,
        s.date_min::TIMESTAMP::DATE AS date_debut,
        s.date_max::TIMESTAMP::DATE AS date_fin,
        s."precision" As precision_geographique,
        o.niveau_precision AS niveau_precision_diffusion,
        o.geom AS geometrie_2154
    FROM gn_synthese.synthese AS s 
        JOIN obs_in_savoie AS o
            ON s.id_synthese = o.id_synthese
        JOIN taxonomie.taxref AS t
            ON s.cd_nom = t.cd_nom
        JOIN gn_meta.t_datasets AS j
            ON j.id_dataset = s.id_dataset
        JOIN gn_meta.t_acquisition_frameworks AS c
            ON c.id_acquisition_framework = j.id_acquisition_framework
        JOIN ref_nomenclatures.t_nomenclatures AS n
            ON s.id_nomenclature_valid_status = n.id_nomenclature 
) TO stdout
WITH (format csv, header, delimiter E'\t');
