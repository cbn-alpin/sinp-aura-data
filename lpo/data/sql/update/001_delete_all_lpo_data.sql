-- Suppression de toutes les données de la LPO + l'utilisateur importé lors de
-- la transmission de données de 2021.
-- Si la table `gn2pg_lpo.data_json` existe, les triggers sont déclenchés.
-- Usage: psql -h "localhost" -U "<db-owner-name>" -d "<db-name>" -f <path-to-this-sql-file>
-- Ex.: psql -h "localhost" -U "geonatadmin" -d "geonature2db" -f ~/data/lpo/data/sql/update/001_*

BEGIN ;

DELETE FROM gn_synthese.cor_area_synthese AS a
USING gn_synthese.synthese AS s
WHERE a.id_synthese = s.id_synthese
    AND s.id_source = gn_synthese.get_id_source_by_name('lpo') ;

DELETE FROM gn_synthese.synthese AS s
WHERE s.id_source = gn_synthese.get_id_source_by_name('lpo') ;

CREATE TEMPORARY TABLE delete_dataset (
   id_dataset int,
   PRIMARY KEY (id_dataset)
) ;

INSERT INTO delete_dataset (id_dataset)
    SELECT DISTINCT d.id_dataset
    FROM gn_meta.t_datasets AS d
        LEFT JOIN gn_synthese.synthese AS s
            ON d.id_dataset = s.id_dataset
    WHERE s.id_synthese IS NULL ;

CREATE TEMPORARY TABLE delete_role (
	id_role int
);

INSERT INTO delete_role (id_role)
    SELECT DISTINCT cda.id_role
    FROM gn_meta.cor_dataset_actor AS cda
        INNER JOIN delete_dataset AS dd
            ON cda.id_dataset = dd.id_dataset
    WHERE cda.id_role IS NOT NULL ;

DELETE FROM gn_meta.cor_dataset_actor AS ac
USING delete_dataset AS td
WHERE ac.id_dataset = td.id_dataset ;

DELETE FROM gn_meta.cor_dataset_territory AS te
USING delete_dataset AS td
WHERE te.id_dataset = td.id_dataset;

DELETE FROM gn_meta.cor_dataset_protocol AS pro
USING delete_dataset AS td
WHERE pro.id_dataset = td.id_dataset ;

DELETE FROM gn_meta.t_datasets AS d
USING delete_dataset AS td
WHERE d.id_dataset = td.id_dataset ;

CREATE TEMPORARY TABLE delete_acquisition_framework (
   id_acquisition_framework int,
   PRIMARY KEY (id_acquisition_framework)
) ;

INSERT INTO delete_acquisition_framework (id_acquisition_framework)
    SELECT ac.id_acquisition_framework
    FROM gn_meta.t_acquisition_frameworks AS ac
        LEFT JOIN gn_meta.t_datasets AS d
            ON ac.id_acquisition_framework = d.id_acquisition_framework
    WHERE (ac.is_parent IS NULL OR ac.is_parent = FALSE)
    GROUP BY ac.id_acquisition_framework
    HAVING COUNT(d.*) = 0 ;

INSERT INTO delete_role (id_role)
    SELECT DISTINCT cda.id_role
    FROM gn_meta.cor_acquisition_framework_actor AS cda
    	INNER JOIN delete_acquisition_framework AS daf
            ON cda.id_acquisition_framework = daf.id_acquisition_framework
    WHERE cda.id_role IS NOT NULL ;

DELETE FROM gn_meta.cor_acquisition_framework_actor AS ac
USING delete_acquisition_framework AS df
WHERE ac.id_acquisition_framework = df.id_acquisition_framework ;

DELETE FROM gn_meta.cor_acquisition_framework_objectif AS obj
USING delete_acquisition_framework AS df
WHERE obj.id_acquisition_framework = df.id_acquisition_framework;

DELETE FROM gn_meta.cor_acquisition_framework_publication AS pub
USING delete_acquisition_framework AS df
WHERE pub.id_acquisition_framework = df.id_acquisition_framework;

DELETE FROM gn_meta.cor_acquisition_framework_voletsinp AS si
USING delete_acquisition_framework AS df
WHERE si.id_acquisition_framework = df.id_acquisition_framework;

DELETE FROM gn_meta.t_acquisition_frameworks AS af
USING delete_acquisition_framework AS df
WHERE af.id_acquisition_framework = df.id_acquisition_framework;

--delete meta cadre doesn't used
DELETE FROM delete_acquisition_framework ;

INSERT INTO delete_acquisition_framework (id_acquisition_framework)
    SELECT DISTINCT ac.id_acquisition_framework
    FROM gn_meta.t_acquisition_frameworks AS ac
        LEFT JOIN gn_meta.t_datasets AS d
            ON ac.id_acquisition_framework = d.id_acquisition_framework
        LEFT JOIN gn_meta.t_acquisition_frameworks AS ac_child
            ON ac.acquisition_framework_parent_id = ac_child.id_acquisition_framework
    WHERE d.id_dataset IS NULL
        AND ac.is_parent = TRUE
        AND ac_child.id_acquisition_framework IS NULL ;

INSERT INTO delete_role (id_role)
    SELECT DISTINCT cda.id_role
    FROM gn_meta.cor_acquisition_framework_actor AS cda
        INNER JOIN delete_acquisition_framework AS daf
            ON cda.id_acquisition_framework = daf.id_acquisition_framework
    WHERE cda.id_role IS NOT NULL ;

DELETE FROM gn_meta.cor_acquisition_framework_actor AS ac
USING delete_acquisition_framework AS df
WHERE ac.id_acquisition_framework = df.id_acquisition_framework ;

DELETE FROM gn_meta.cor_acquisition_framework_objectif AS obj
USING delete_acquisition_framework AS df
WHERE obj.id_acquisition_framework = df.id_acquisition_framework;

DELETE FROM gn_meta.cor_acquisition_framework_publication AS pub
USING delete_acquisition_framework AS df
WHERE pub.id_acquisition_framework = df.id_acquisition_framework;

DELETE FROM gn_meta.cor_acquisition_framework_voletsinp AS si
USING delete_acquisition_framework AS df
WHERE si.id_acquisition_framework = df.id_acquisition_framework;

DELETE FROM gn_meta.t_acquisition_frameworks AS af
USING delete_acquisition_framework AS df
WHERE af.id_acquisition_framework = df.id_acquisition_framework;

DELETE FROM gn_synthese.t_sources AS sou
WHERE sou.id_source = gn_synthese.get_id_source_by_name('lpo');

DO $$
DECLARE
    delete_id_role RECORD ;
BEGIN
      FOR delete_id_role IN
        SELECT DISTINCT dr.id_role
        FROM utilisateurs.t_roles AS r
            INNER JOIN delete_role AS dr
                ON dr.id_role = r.id_role
		WHERE pass_plus IS NULL
      LOOP
        RAISE NOTICE 'trying to delete role id  %', delete_id_role.id_role ;
          BEGIN
              DELETE FROM utilisateurs.t_roles AS r WHERE r.id_role = delete_id_role.id_role ;
              RAISE NOTICE 'Deleted role id: %', delete_id_role.id_role ;
          EXCEPTION
              WHEN others THEN
                  -- we ignore the error
              END;
      END LOOP;
END $$;

TRUNCATE TABLE gn2pg_lpo.data_json CONTINUE IDENTITY RESTRICT;

TRUNCATE TABLE gn2pg_lpo.datasets_json CONTINUE IDENTITY RESTRICT;

TRUNCATE TABLE gn2pg_lpo.download_log CONTINUE IDENTITY RESTRICT;

TRUNCATE TABLE gn2pg_lpo.error_log CONTINUE IDENTITY RESTRICT;

TRUNCATE TABLE gn2pg_lpo.increment_log CONTINUE IDENTITY RESTRICT;

COMMIT;
