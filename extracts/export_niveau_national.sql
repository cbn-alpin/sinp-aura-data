--Requête réalisée par Théo Deboffe theo.deboffe@cbnmc.fr
copy (WITH 
--crée un objet json permettant de convertir les noms des départements en code 
jsonb_dept_correspondance as (select json_object('{AIN,01, ALLIER, 03, ARDECHE, 07, CANTAL, 15, DROME, 26, HAUTE-LOIRE, 43,
									  HAUTE-SAVOIE, 74, ISERE, 38, LOIRE, 42, PUY-DE-DOME, 63, RHONE, 69, SAVOIE, 73}')::jsonb as cor),
--permet de filtrer les datasets à exporter 
cda AS (
         SELECT d_1.id_dataset,
            string_agg(DISTINCT orga.nom_organisme::text, ' | '::text) AS acteurs
           FROM gn_meta.t_datasets d_1
             left JOIN gn_meta.cor_dataset_actor act ON act.id_dataset = d_1.id_dataset
             left JOIN ref_nomenclatures.t_nomenclatures nomencl ON nomencl.id_nomenclature = act.id_nomenclature_actor_role
             LEFT JOIN utilisateurs.bib_organismes orga ON orga.id_organisme = act.id_organism
             LEFT JOIN utilisateurs.t_roles roles ON roles.id_role = act.id_role
          WHERE d_1.id_acquisition_framework in (1, 10, 11, 12, 14, 15, 16, 17, 18, 2, 3, 4, 5, 6, 7)
          GROUP BY d_1.id_dataset),
--permet de sélectionner les datasets devant être exporter en localisation précises
dataset_precis as (
select id_dataset from gn_meta.t_datasets d_1 where unique_dataset_id in ( 'ec886fad-500a-4683-85aa-2b7ab55b2ace'::uuid, 'dc9e5739-bb38-463e-a45b-f769bc41f834'::uuid,
          '062b6846-02d4-4a20-a3e9-1a7b0ed08b6a'::uuid,'479f0cd8-44d5-40e2-9856-fbb8792b2fc0'::uuid,'20ce236f-062a-402e-8589-1634f1133565'::uuid,
          '2942baaf-9192-48b2-9cd6-b6054f9a8b11'::uuid)
),
-- permet de récupérer toutes les information des observations de synthèse pour les données à exporter c'est ces données qui fond être floutées en fonction de la sensibilité des taxons
synthese_export as (select * from gn_synthese.synthese s where s.id_dataset in (select id_dataset from cda)),

-- récupération de la communes des données à exporter sans géométrie pouvant être diffusées de façon précise
ss_geom_com as (select la_com.id_type, la_com.area_name, la_com.geom com_geom, s.id_synthese
from synthese_export s 
	left join gn_synthese.cor_area_synthese cas_com 
		on cas_com.id_synthese = s.id_synthese
	left join ref_geo.l_areas la_com 
		on la_com.id_area = cas_com.id_area and la_com.id_type = 25 
where  (s.id_nomenclature_sensitivity = 65 or s.id_nomenclature_sensitivity is null ) and s.the_geom_local is null and la_com.id_area is not null), 

-- récupération du départements des données à exporter sans géométrie pouvant être diffusées de façon précise
ss_geom_dept as (select la_dept.id_type, la_dept.area_name, la_dept.geom dept_geom, s.id_synthese
from synthese_export s 
	left join gn_synthese.cor_area_synthese cas_dept 
		on cas_dept.id_synthese = s.id_synthese
	left join ref_geo.l_areas la_dept 
		on la_dept.id_area = cas_dept.id_area and la_dept.id_type = 26
where (s.id_nomenclature_sensitivity = 65 or s.id_nomenclature_sensitivity is null )  and s.the_geom_local is null and la_dept.id_area is not null
),
--floutage des données  sensible à la commune ou des données qui n'ont pas de géométrie et qui doivent être floutées à la maille 
ss_geom_com_floutage_com as (select la_com.id_type, la_com.area_name, la_com.geom com_geom, s.id_synthese
from synthese_export s 
	left join gn_synthese.cor_area_synthese cas_com 
		on cas_com.id_synthese = s.id_synthese
	left join ref_geo.l_areas la_com 
		on la_com.id_area = cas_com.id_area and la_com.id_type = 25 
where (s.id_nomenclature_sensitivity = 66 or (s.id_nomenclature_sensitivity = 67 and s.the_geom_local is null)) and la_com.id_area is not null), 

--floutage des données sensible au département ou des données qui n'ont pas de géométrie et qui doivent être floutées à la maille
ss_geom_dept_floutage_dept as (select la_dept.id_type, la_dept.area_name, la_dept.geom dept_geom, s.id_synthese
from synthese_export s 
	left join gn_synthese.cor_area_synthese cas_dept 
		on cas_dept.id_synthese = s.id_synthese
	left join ref_geo.l_areas la_dept 
		on la_dept.id_area = cas_dept.id_area and la_dept.id_type = 26
where (s.id_nomenclature_sensitivity = 66 or (s.id_nomenclature_sensitivity = 67 and s.the_geom_local is null)) and  la_dept.id_area is not null
),

--regroupement de toutes les géométries floutées ou rattachées à la communes ou au département
geom_synthese as (
-- récupération des communes ou des départements (si la données n'est pas rattachées à la commune) pour les données devant être floutées à la commune
-- si les données n'ont pas de géométrie associées et qu'elles doivent être floutées à la maille récupération de la géométrie de la commune
(select distinct on (s.id_synthese) coalesce(com.com_geom, dept.dept_geom) the_geom_2154, s.id_synthese, true floutage, false export_geom
from  synthese_export s 
left join ss_geom_com_floutage_com com 
	on com.id_synthese = s.id_synthese 
left join ss_geom_dept_floutage_dept dept
	on dept.id_synthese  = s.id_synthese 
where (s.id_nomenclature_sensitivity = 66 or (s.id_nomenclature_sensitivity = 67 and s.the_geom_local is null)) 
and coalesce(com.com_geom, dept.dept_geom) is not null
order by id_synthese)
union 

-- récupération de la maille les données devant être floutées à la maille
(select distinct on (s.id_synthese) la_maille.geom the_geom_2154, s.id_synthese , true floutage, true export_geom 
from synthese_export s 
	left join gn_synthese.cor_area_synthese cas 
		on cas.id_synthese = s.id_synthese
	inner join ref_geo.l_areas la_maille 
		on la_maille.id_area = cas.id_area and la_maille.id_type = 37 
where s.id_nomenclature_sensitivity = 67  and s.the_geom_local is not null
order by s.id_synthese )

union
-- récupération de la géométrie précise pour les données ppouvant être diffuser de manière précise. Si la données n'a pas de géométrie récupration de la commune ou du département 
(select s.the_geom_local the_geom_2154, s.id_synthese, false floutage, case when s.the_geom_local is not null then true else false end export_geom
from synthese_export s
left join ss_geom_com com 
	on com.id_synthese = s.id_synthese 
left join ss_geom_dept dept
	on dept.id_synthese  = s.id_synthese 
where  (s.id_nomenclature_sensitivity = 65 or s.id_nomenclature_sensitivity is null )  and coalesce(s.the_geom_local, com_geom, dept_geom) is not null )),

areas AS (
         SELECT ta.id_type,
            ta.type_code,
            ta.ref_version,
            a_1.id_area,
            a_1.area_code,
            a_1.area_name
           FROM ref_geo.bib_areas_types ta
             JOIN ref_geo.l_areas a_1 ON ta.id_type = a_1.id_type
          WHERE ta.type_code::text = ANY (ARRAY['DEP'::character varying, 'COM'::character varying, 'M1'::character varying]::text[])
        ),
-- récupération de toutes les géométries des relevés celles pour les observation précises avec le floutage adéquate et les autres qui sont floutées à la maille. 
geom_obs as(
-- récupération des données devant être diffusées en précis et des données ayant déjà été floutées
		(select gs.id_synthese, gs.the_geom_2154, gs.floutage, gs.export_geom  
			from geom_synthese gs 
				left join gn_synthese.synthese s 
					on gs.id_synthese = s.id_synthese 
			where gs.floutage = true or s.id_dataset in (select id_dataset from dataset_precis) 
			
		)
	union
		(select distinct on (s.id_synthese) s.id_synthese,  la_maille.geom the_geom_2154, true floutage, true export_geom
		from synthese_export s 
			inner join geom_synthese gs
				on gs.id_synthese = s.id_synthese 
			left join gn_synthese.cor_area_synthese cas 
				on cas.id_synthese = s.id_synthese
			inner join ref_geo.l_areas la_maille 
				on la_maille.id_area = cas.id_area and la_maille.id_type = 37 
		where gs.floutage = false and s.id_dataset in (select id_dataset from cda) and s.id_dataset not in (select id_dataset from dataset_precis) 
		order by s.id_synthese)
	)
 SELECT s.id_synthese AS "ID_synthese",
    s.entity_source_pk_value AS "idOrigine",
    s.unique_id_sinp AS "idSINPOccTax",
    s.unique_id_sinp_grp AS "idSINPRegroupement",
    d.unique_dataset_id AS "idSINPJdd",
    s.date_min::date AS "dateDebut",
    s.date_min::time without time zone AS "heureDebut",
    s.date_max::date AS "dateFin",
    s.date_max::time without time zone AS "heureFin",
    t.cd_nom AS "cdNom",
    t.cd_ref AS "codeHabRef",
    h.cd_hab AS habitat,
    h.lb_code AS "codeHabitat",
    'Habref 5.0 2019'::text AS "versionRef",
    cda.acteurs AS "organismeGestionnaireDonnee",
    a.jcode ->> 'DEP'::text AS "nomDepartement",
    dept_cor.cor->>(a.jcode ->> 'DEP'::text) AS "codeDepartement",
    a.jversion ->> 'DEP'::text AS "anneeRefDepartement",
    case when s.id_nomenclature_sensitivity = 68 then null else a.jname ->> 'COM'::text end  AS "nomCommune",
    case when s.id_nomenclature_sensitivity = 68 then null else a.jcode ->> 'COM'::text end AS "codeCommune",
    a.jversion ->> 'COM'::text AS "anneeRefCommune",
    a.jcode ->> 'M10'::text AS "codeMaille",
    s.nom_cite AS "nomCite",
    s.count_min AS "denombrementMin",
    s.count_max AS "denombrementMax",
    s.altitude_min AS "altitudeMin",
    s.altitude_max AS "altitudeMax",
    (s.altitude_min + s.altitude_max) / 2 AS "altitudeMoyenne",
    s.depth_min AS "profondeurMin",
    s.depth_max AS "profondeurMax",
    (s.depth_max - s.depth_min) / 2 AS "profondeurMoyenne",
    s.observers AS observateur,
    s.determiner AS determinateur,
    s.digital_proof AS "uRLPreuveNumerique",
    s.non_digital_proof AS "preuveNonNumerique",
    case when gobs.export_geom then st_asewkt(gobs.the_geom_2154) else null end AS geometrie,
    case when gobs.floutage then  round(|/(st_area(gobs.the_geom_2154)/pi()))::INT else s."precision" end  AS "precisionGeometrie",
    s.place_name AS "nomLieu",
    s.comment_context AS commentaire,
    s.comment_description AS "obsDescription",
    s.meta_create_date AS "dateDetermination",
    s.meta_update_date AS "dEEDateTransformation",
    COALESCE(s.meta_update_date, s.meta_create_date) AS "dEEDateDerniereModification",
    s.reference_biblio AS "referenceBiblio",
    ( SELECT css.meta_create_date
           FROM gn_sensitivity.cor_sensitivity_synthese css
          WHERE css.uuid_attached_row = s.unique_id_sinp
          ORDER BY css.meta_create_date DESC
         LIMIT 1) AS "sensiDateAttribution",
    n1.label_default AS "natureObjetGeo",
    n2.label_default AS "methodeRegroupement",
    n4.label_default AS "obsTechnique",
    n5.label_default AS "occStatutBiologique",
    n6.label_default AS "occEtatBiologique",
    n7.label_default AS "occNaturalite",
    n8.label_default AS "preuveExistante",
    n9.label_default AS "diffusionNiveauPrecision",
    n10.label_default AS "occStadeDeVie",
    n11.label_default AS "occSexe",
    n12.label_default AS "objetDenombrement",
    n13.label_default AS "typeDenombrement",
    n14.label_default AS "sensiNiveau",
    n15.label_default AS "statutObservation",
    case when gobs.floutage then 'Oui' else n16.label_default end  AS "dEEFloutage",
    n17.label_default AS "statutSource",
    n19.label_default AS "occMethodeDetermination",
    n20.label_default AS "occComportement",
    n21.label_default AS "dSPublique"
   FROM synthese_export s
     JOIN taxonomie.taxref t ON t.cd_nom = s.cd_nom
     JOIN gn_meta.t_datasets d ON d.id_dataset = s.id_dataset
     JOIN gn_meta.t_acquisition_frameworks af ON d.id_acquisition_framework = af.id_acquisition_framework
     JOIN gn_synthese.t_sources sources ON sources.id_source = s.id_source
     left JOIN cda ON d.id_dataset = cda.id_dataset
     left join geom_obs gobs on gobs.id_synthese = s.id_synthese 
     LEFT JOIN LATERAL ( SELECT d_1.id_synthese,
            json_object_agg(d_1.type_code, d_1.o_name) AS jname,
            json_object_agg(d_1.type_code, d_1.o_code) AS jcode,
            json_object_agg(d_1.type_code, d_1.ref_version) AS jversion
           FROM ( SELECT sa.id_synthese,
                    ta.type_code,
                    string_agg(ta.area_name::text, '|'::text) AS o_name,
                    string_agg(ta.area_code::text, '|'::text) AS o_code,
                    string_agg(ta.ref_version::character varying::text, '|'::text) AS ref_version
                   FROM gn_synthese.cor_area_synthese sa
                     JOIN areas ta ON ta.id_area = sa.id_area
                  WHERE sa.id_synthese = s.id_synthese
                  GROUP BY sa.id_synthese, ta.type_code) d_1
          GROUP BY d_1.id_synthese) a ON true
     LEFT JOIN ref_habitats.habref h ON h.cd_hab = s.cd_hab
     LEFT JOIN ref_nomenclatures.t_nomenclatures n1 ON s.id_nomenclature_geo_object_nature = n1.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n2 ON s.id_nomenclature_grp_typ = n2.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n4 ON s.id_nomenclature_obs_technique = n4.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n5 ON s.id_nomenclature_bio_status = n5.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n6 ON s.id_nomenclature_bio_condition = n6.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n7 ON s.id_nomenclature_naturalness = n7.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n8 ON s.id_nomenclature_exist_proof = n8.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n9 ON s.id_nomenclature_diffusion_level = n9.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n10 ON s.id_nomenclature_life_stage = n10.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n11 ON s.id_nomenclature_sex = n11.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n12 ON s.id_nomenclature_obj_count = n12.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n13 ON s.id_nomenclature_type_count = n13.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n14 ON s.id_nomenclature_sensitivity = n14.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n15 ON s.id_nomenclature_observation_status = n15.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n16 ON s.id_nomenclature_blurring = n16.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n17 ON s.id_nomenclature_source_status = n17.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n18 ON s.id_nomenclature_info_geo_type = n18.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n19 ON s.id_nomenclature_determination_method = n19.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n20 ON s.id_nomenclature_behaviour = n20.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n21 ON d.id_nomenclature_data_origin = n21.id_nomenclature
     left join jsonb_dept_correspondance dept_cor on true
where s.id_nomenclature_sensitivity <> 69 or s.id_nomenclature_sensitivity is null) to '/tmp_hote/export_1.csv' delimiter E'\t' quote '"' escape '"' null '\N' csv header;

-- 9335981 données 

