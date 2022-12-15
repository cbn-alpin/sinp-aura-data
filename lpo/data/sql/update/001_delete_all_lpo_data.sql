-- Suppression de toutes les données de la LPO + l'utilisateur importé lors de
-- la transmission de données de 2021.
-- Si la table `gn2pg_lpo.data_json` existe, les triggers sont déclenchés.
-- Usage: psql -h "localhost" -U "<db-owner-name>" -d "<db-name>" -f <path-to-this-sql-file>
-- Ex.: psql -h "localhost" -U "geonatadmin" -d "geonature2db" -f ~/data/lpo/data/sql/update/001_*

BEGIN ;

DELETE FROM gn_synthese.cor_area_synthese AS a
USING gn_synthese.synthese AS s
WHERE a.id_synthese = s.id_synthese and s.id_source = gn_synthese.get_id_source_by_name('lpo');

DELETE FROM gn_synthese.synthese AS s
WHERE s.id_source = gn_synthese.get_id_source_by_name('lpo');

CREATE TEMPORARY TABLE delete_dataset (
   id_dataset int ,
   PRIMARY KEY (id_dataset)
) ;

INSERT INTO delete_dataset (id_dataset)
SELECT DISTINCT d.id_dataset
FROM gn_meta.t_datasets d
	LEFT JOIN gn_synthese.synthese s ON d.id_dataset = s.id_dataset
WHERE s.id_synthese IS NULL; 

---exécution stopper ici
CREATE TEMPORARY TABLE delete_role (
	id_role int
);
INSERT INTO delete_role (id_role)
SELECT DISTINCT cda.id_role  
FROM gn_meta.cor_dataset_actor cda 
	inner JOIN delete_dataset dd ON cda.id_dataset = dd.id_dataset WHERE cda.id_role IS NOT NULL ;

DELETE FROM gn_meta.cor_dataset_actor AS ac
USING  delete_dataset AS td
WHERE ac.id_dataset = td.id_dataset ;

DELETE FROM gn_meta.cor_dataset_territory AS te
USING  delete_dataset AS td
WHERE te.id_dataset = td.id_dataset;

DELETE FROM gn_meta.cor_dataset_protocol AS pro
USING  delete_dataset AS td
WHERE pro.id_dataset = td.id_dataset ;

DELETE FROM gn_meta.t_datasets AS d
USING  delete_dataset AS td
WHERE d.id_dataset = td.id_dataset  ;

CREATE TEMPORARY TABLE delete_acquisition_framework (
   id_acquisition_framework int ,
   PRIMARY KEY (id_acquisition_framework)
) ;

INSERT INTO delete_acquisition_framework (id_acquisition_framework)
SELECT DISTINCT d.id_acquisition_framework 
FROM gn_meta.t_acquisition_frameworks ac
	LEFT JOIN gn_meta.t_datasets d ON ac.id_acquisition_framework = d.id_acquisition_framework
WHERE d.id_dataset IS NULL AND NOT ac.is_parent; 


INSERT INTO delete_role (id_role)
SELECT DISTINCT cda.id_role 
FROM gn_meta.cor_acquisition_framework_actor cda 
	inner JOIN delete_acquisition_framework daf ON cda.id_acquisition_framework  = daf.id_acquisition_framework;

DELETE FROM gn_meta.cor_acquisition_framework_actor AS ac
USING  delete_acquisition_framework AS df
WHERE ac.id_acquisition_framework = df.id_acquisition_framework ;

DELETE FROM gn_meta.cor_acquisition_framework_objectif AS obj
USING  delete_acquisition_framework AS df
WHERE obj.id_acquisition_framework = df.id_acquisition_framework;

DELETE FROM gn_meta.cor_acquisition_framework_publication AS pub
USING delete_acquisition_framework AS df
WHERE pub.id_acquisition_framework = df.id_acquisition_framework;

DELETE FROM gn_meta.cor_acquisition_framework_voletsinp AS si
USING  delete_acquisition_framework AS df
WHERE si.id_acquisition_framework = df.id_acquisition_framework;

DELETE FROM gn_meta.t_acquisition_frameworks AS af
USING  delete_acquisition_framework AS df
WHERE df.id_acquisition_framework = df.id_acquisition_framework;

--delete meta cadre doesn't used 
DELETE FROM delete_acquisition_framework;

INSERT INTO delete_acquisition_framework (id_acquisition_framework)
SELECT DISTINCT ac.id_acquisition_framework 
FROM gn_meta.t_acquisition_frameworks ac
	LEFT JOIN gn_meta.t_datasets d ON ac.id_acquisition_framework = d.id_acquisition_framework
	LEFT JOIN gn_meta.t_acquisition_frameworks ac_child ON ac.acquisition_framework_parent_id = ac_child.id_acquisition_framework 
WHERE d.id_dataset IS NULL AND ac.is_parent AND ac_child.id_acquisition_framework IS NULL  ; 

INSERT INTO delete_role (id_role)
SELECT DISTINCT cda.id_role 
FROM gn_meta.cor_acquisition_framework_actor cda 
	inner JOIN delete_acquisition_framework daf ON cda.id_acquisition_framework  = daf.id_acquisition_framework;

DELETE FROM gn_meta.cor_acquisition_framework_actor AS ac
USING  delete_acquisition_framework AS df
WHERE ac.id_acquisition_framework = df.id_acquisition_framework ;

DELETE FROM gn_meta.cor_acquisition_framework_objectif AS obj
USING  delete_acquisition_framework AS df
WHERE obj.id_acquisition_framework = df.id_acquisition_framework;

DELETE FROM gn_meta.cor_acquisition_framework_publication AS pub
USING delete_acquisition_framework AS df
WHERE pub.id_acquisition_framework = df.id_acquisition_framework;

DELETE FROM gn_meta.cor_acquisition_framework_voletsinp AS si
USING  delete_acquisition_framework AS df
WHERE si.id_acquisition_framework = df.id_acquisition_framework;

DELETE FROM gn_meta.t_acquisition_frameworks AS af
USING  delete_acquisition_framework AS df
WHERE df.id_acquisition_framework = df.id_acquisition_framework;

DELETE FROM gn_synthese.t_sources AS sou
WHERE sou.id_source = gn_synthese.get_id_source_by_name('lpo');

DO $$
DECLARE
    delete_id_role int;
BEGIN
      FOR delete_id_role IN 
      SELECT DISTINCT dr.id_role FROM utilisateurs.t_roles r INNER JOIN delete_role dr ON dr.id_role = r.id_role 
		WHERE r.id_role = dr.id_role AND pass_plus IS NULL 
      LOOP
        RAISE NOTICE 'trying to delete role id  %',pr.id;
          BEGIN
              DELETE FROM utilisateurs.t_roles r WHERE r;
              RAISE NOTICE 
              'Deleted role id: %',pr.id;
          EXCEPTION
              WHEN others THEN 
                  -- we ignore the error
              END;
      END LOOP;
END $$;
COMMIT;
/*
select * from gn_meta.cor_acquisition_framework_actor

select * from utilisateurs.t_roles tr where pass is null and pass_plus is null and not groupe 

select * FROM delete_acquisition_frameworks dac left join gn_meta.t_acquisition_frameworks taf on dac.unique_acquisition_framework = taf.unique_acquisition_framework_id  
where taf.unique_acquisition_framework_id in ('57b7d0f2-4183-4b7b-8f08-6e105d476dc5', '65b786cb-f77c-66ff-e053-2614a8c00c2e')

select distinct  dac.unique_acquisition_framework, tr.* 
FROM delete_acquisition_frameworks dac 
left join gn_meta.t_acquisition_frameworks ac on ac.unique_acquisition_framework_id = dac.unique_acquisition_framework
left join gn_meta.t_datasets td on td.id_acquisition_framework = ac.id_acquisition_framework
left join gn_meta.cor_dataset_actor coa  on coa.id_dataset = td.id_dataset
left join utilisateurs.t_roles tr on tr.id_role = coa.id_role 


DELETE FROM gn_meta.cor_acquisition_framework_actor AS ac
USING  gn_meta.t_acquisition_frameworks AS af, delete_acquisition_frameworks AS df
WHERE ac.id_acquisition_framework = af.id_acquisition_framework
    AND af.unique_acquisition_framework_id = df.unique_acquisition_framework ;
   
   
select distinct taf.id_acquisition_framework,  s.id_source 
from gn_meta.t_acquisition_frameworks taf
left join gn_meta.t_datasets td 
	on taf.id_acquisition_framework = td.id_acquisition_framework 
left join gn_synthese.synthese s
	on s.id_dataset = td.id_dataset 
where taf.unique_acquisition_framework_id in ('57b7d0f2-4183-4b7b-8f08-6e105d476dc5', '65b786cb-f77c-66ff-e053-2614a8c00c2e')

select distinct tr.* 
FROM delete_acquisition_frameworks dac 
left join gn_meta.t_acquisition_frameworks ac on ac.unique_acquisition_framework_id = dac.unique_acquisition_framework
left join gn_meta.cor_acquisition_framework_actor cafa on cafa.id_acquisition_framework  = ac.id_acquisition_framework
left join utilisateurs.t_roles tr on tr.id_role = cafa.id_role 


SELECT * 
FROM gn_meta.t_datasets td 
	LEFT JOIN gn_synthese.synthese s 
		ON td.id_dataset = s.id_synthese 
WHERE s.id_synthese IS NULL 


SELECT * FROM gn_meta.t_acquisition_frameworks taf 
WHERE taf.is_parent 
*/
