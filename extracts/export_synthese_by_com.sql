/*Prermet d'exporter et de flouter en fonction de la sensibilité les données de synthèse à partir d'une liste de commune 
Si les données doivent être floutées à la commune ou au département seul les codes insee sont exportés et non la gémétries
*/

create table gn_exports.pnr_pilat as (with pnr as( 
select unnest(array['69091','69080','43227','42129','42308','69252','42280','42271','42246','42322','42115','42326','42327','42132','07056','07258','42207','07010','69235','42218','43204','42287','42067','07041','42028','42201','07344','42329','42023','43172','07347','42101','42272','07160','43223','43163','07143','42172','42124','42237','69236','42064','69064','69118','42085','42017','42286','69253','42053','42051','07333','42056','69097','69193','42018','42191','42167','42224','42265','42093','69007','42210','07044','42310','07342','42168','42044','07265','69119','42306','07310','69189','07243','43205','42139','07212']) code
), 

synthese_export as (select distinct s.id_synthese, s.id_nomenclature_diffusion_level, s.id_nomenclature_sensitivity, s.the_geom_point, s.the_geom_4326  
from  gn_synthese.synthese s 
left join gn_synthese.cor_area_synthese cas on s.id_synthese = cas.id_synthese 
left join ref_geo.l_areas a on cas.id_area = a.id_area 
inner join pnr p on a.area_code  = p.code ),

geom_export as ((select distinct on (es.id_synthese) es.id_synthese, null::text geojson_4326, sa.communes, null::float x_centroid_4326, null::float y_centroid_4326, 'commune' type_floutage, de.departements    
from synthese_export es 
	left join gn_synthese.cor_area_synthese cas_commune on es.id_synthese = cas_commune.id_synthese 
	left join ref_geo.l_areas a_commune on a_commune.id_area = cas_commune.id_area 
	LEFT JOIN LATERAL ( SELECT cas.id_synthese,
            string_agg(DISTINCT concat(a_1.area_name, ' (', a_1.area_code, ')'), ', '::text) AS communes
           FROM gn_synthese.cor_area_synthese cas
             JOIN ref_geo.l_areas a_1 ON cas.id_area = a_1.id_area
             JOIN ref_geo.bib_areas_types ta ON ta.id_type = a_1.id_type AND ta.type_code::text = 'COM'::text
          WHERE cas.id_synthese = es.id_synthese
          GROUP BY cas.id_synthese) sa ON true
    LEFT JOIN LATERAL ( SELECT cas.id_synthese,
            string_agg(DISTINCT concat(a_1.area_name, ' (', a_1.area_code, ')'), ', '::text) AS departements
           FROM gn_synthese.cor_area_synthese cas
             JOIN ref_geo.l_areas a_1 ON cas.id_area = a_1.id_area
             JOIN ref_geo.bib_areas_types ta ON ta.id_type = a_1.id_type AND ta.type_code::text = 'DEP'::text
          WHERE cas.id_synthese = es.id_synthese
          GROUP BY cas.id_synthese) de ON true
where  es.id_nomenclature_sensitivity = 66 and a_commune.id_type = 25 )
union all
(select distinct on (es.id_synthese) es.id_synthese, a_maille.geojson_4326, sa.communes, null::float x_centroid_4326, null::float y_centroid_4326, 'maille' type_floutage, de.departements         
from synthese_export es 
	left join gn_synthese.cor_area_synthese cas_maille on es.id_synthese = cas_maille.id_synthese 
	left join ref_geo.l_areas a_maille on a_maille.id_area = cas_maille.id_area
	LEFT JOIN LATERAL ( SELECT cas.id_synthese,
            string_agg(DISTINCT concat(a_1.area_name, ' (', a_1.area_code, ')'), ', '::text) AS communes
           FROM gn_synthese.cor_area_synthese cas
             JOIN ref_geo.l_areas a_1 ON cas.id_area = a_1.id_area
             JOIN ref_geo.bib_areas_types ta ON ta.id_type = a_1.id_type AND ta.type_code::text = 'COM'::text
          WHERE cas.id_synthese = es.id_synthese
          GROUP BY cas.id_synthese) sa ON true
   LEFT JOIN LATERAL ( SELECT cas.id_synthese,
            string_agg(DISTINCT concat(a_1.area_name, ' (', a_1.area_code, ')'), ', '::text) AS departements
           FROM gn_synthese.cor_area_synthese cas
             JOIN ref_geo.l_areas a_1 ON cas.id_area = a_1.id_area
             JOIN ref_geo.bib_areas_types ta ON ta.id_type = a_1.id_type AND ta.type_code::text = 'DEP'::text
          WHERE cas.id_synthese = es.id_synthese
          GROUP BY cas.id_synthese) de ON true
where es.id_nomenclature_sensitivity = 67 and a_maille.id_type = 37)
union all 
(select distinct on (es.id_synthese) es.id_synthese, null::text geojson_4326, null::text communes, null::float x_centroid_4326, null::float y_centroid_4326, 'departement' type_floutage, de.departements   
from synthese_export es 
	left join gn_synthese.cor_area_synthese cas_departement on es.id_synthese = cas_departement.id_synthese 
	left join ref_geo.l_areas a_departement on a_departement.id_area = cas_departement.id_area
	LEFT JOIN LATERAL ( SELECT cas.id_synthese,
            string_agg(DISTINCT concat(a_1.area_name, ' (', a_1.area_code, ')'), ', '::text) AS departements
           FROM gn_synthese.cor_area_synthese cas
             JOIN ref_geo.l_areas a_1 ON cas.id_area = a_1.id_area
             JOIN ref_geo.bib_areas_types ta ON ta.id_type = a_1.id_type AND ta.type_code::text = 'DEP'::text
          WHERE cas.id_synthese = es.id_synthese
          GROUP BY cas.id_synthese) de ON true
where es.id_nomenclature_sensitivity = 68 and a_departement.id_type = 26 )
union all (
select es.id_synthese, st_asgeojson(es.the_geom_4326), sa.communes, st_x(st_transform(st_centroid(es.the_geom_point), 4326)) AS x_centroid_4326,
st_y(st_transform(st_centroid(es.the_geom_point), 4326)) AS y_centroid_4326, 'précis' type_floutage, de.departements 
from synthese_export es
	LEFT JOIN LATERAL ( SELECT cas.id_synthese,
            string_agg(DISTINCT concat(a_1.area_name, ' (', a_1.area_code, ')'), ', '::text) AS communes
           FROM gn_synthese.cor_area_synthese cas
             JOIN ref_geo.l_areas a_1 ON cas.id_area = a_1.id_area
             JOIN ref_geo.bib_areas_types ta ON ta.id_type = a_1.id_type AND ta.type_code::text = 'COM'::text
          WHERE cas.id_synthese = es.id_synthese
          GROUP BY cas.id_synthese) sa ON true
    LEFT JOIN LATERAL ( SELECT cas.id_synthese,
            string_agg(DISTINCT concat(a_1.area_name, ' (', a_1.area_code, ')'), ', '::text) AS departements
           FROM gn_synthese.cor_area_synthese cas
             JOIN ref_geo.l_areas a_1 ON cas.id_area = a_1.id_area
             JOIN ref_geo.bib_areas_types ta ON ta.id_type = a_1.id_type AND ta.type_code::text = 'DEP'::text
          WHERE cas.id_synthese = es.id_synthese
          GROUP BY cas.id_synthese) de ON true
where  es.id_nomenclature_sensitivity = 65 or es.id_nomenclature_sensitivity is null
)) 
 

SELECT s.id_synthese,
    s.unique_id_sinp AS uuid_perm_sinp,
    s.unique_id_sinp_grp AS uuid_perm_grp_sinp,
    sd.dataset_name AS jdd_nom,
    sd.unique_dataset_id AS jdd_uuid,
    sd.organisms AS fournisseur,
    s.observers AS observateurs,
    t.cd_ref,
    t.nom_valide,
    t.nom_vern AS nom_vernaculaire,
    t.classe,
    t.famille,
    t.ordre,
    n15.label_default AS statut_observation,
    s.count_min AS nombre_min,
    s.count_max AS nombre_max,
    s.date_min::date AS date_debut,
    s.date_max::date AS date_fin,
    ge.geojson_4326 AS geojson_4326,
    ge.x_centroid_4326,
    ge.y_centroid_4326,
    s."precision" AS precision_geographique,
    ge.communes,
    ge.departements, 
    s.altitude_min AS alti_min,
    n3.label_default AS technique_observation,
    n10.label_default AS stade_vie,
    n5.label_default AS statut_biologique,
    n11.label_default AS sexe,
    n20.label_default AS comportement,
    n17.label_default AS type_source,
    s.additional_data ->> 'precisionLabel'::text AS type_precision,
        CASE
            WHEN ns.cd_nomenclature::text = '0'::text THEN 'donnée non sensible'::text
            WHEN s.id_nomenclature_sensitivity IS NULL THEN ''::text
            ELSE 'donnée sensible'::text
        END AS sensibilite,
        CASE
            WHEN ns.cd_nomenclature::text <> '0'::text OR dl.cd_nomenclature::text <> '5'::text THEN 'donnée confidentielle'::text
            ELSE 'donnée non confidentielle'::text
        END AS confidentialite,
    sd.id_dataset AS jdd_id,
    s.id_digitiser,
    s.id_nomenclature_sensitivity,
    s.id_nomenclature_diffusion_level
   FROM gn_synthese.synthese s
   	inner join synthese_export se on se.id_synthese = s.id_synthese 
     JOIN taxonomie.taxref t ON t.cd_nom = s.cd_nom
	left join geom_export ge on s.id_synthese = ge.id_synthese
	LEFT JOIN LATERAL ( SELECT td.id_dataset,
            td.dataset_name,
            td.unique_dataset_id,
            string_agg(DISTINCT bo.nom_organisme::text, ', '::text) AS organisms
           FROM gn_meta.t_datasets td
             LEFT JOIN gn_meta.cor_dataset_actor cad ON cad.id_dataset = td.id_dataset AND (cad.id_nomenclature_actor_role = ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR'::character varying, '5'::character varying) OR cad.id_nomenclature_actor_role = ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR'::character varying, '6'::character varying))
             LEFT JOIN utilisateurs.bib_organismes bo ON bo.id_organisme = cad.id_organism
          WHERE td.id_dataset = s.id_dataset
          GROUP BY td.id_dataset) sd ON true
     LEFT JOIN ref_nomenclatures.t_nomenclatures n3 ON s.id_nomenclature_obs_technique = n3.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n5 ON s.id_nomenclature_bio_status = n5.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n10 ON s.id_nomenclature_life_stage = n10.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n11 ON s.id_nomenclature_sex = n11.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n15 ON s.id_nomenclature_observation_status = n15.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n17 ON s.id_nomenclature_source_status = n17.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n20 ON s.id_nomenclature_behaviour = n20.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures ns ON s.id_nomenclature_sensitivity = ns.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures dl ON s.id_nomenclature_diffusion_level = dl.id_nomenclature)
