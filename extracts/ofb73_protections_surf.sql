-- attention geometrycollection non prises en compte

with 
liste_p as (
select distinct cd_ref--,code_statut,label_statut
from taxonomie.bdc_statut
where code_statut in ('NV1','NV2','NV3','RV82') 
),

nv1 as (
select distinct cd_ref, 1 as nv1
from taxonomie.bdc_statut
where code_statut = 'NV1'
),

nv2 as (
select distinct cd_ref, 1 as nv2
from taxonomie.bdc_statut
where code_statut = 'NV2'
),

nv3 as (
select distinct cd_ref, 1 as nv3
from taxonomie.bdc_statut
where code_statut = 'NV3'
),

rv82 as (
select distinct cd_ref, 1 as rv82
from taxonomie.bdc_statut
where code_statut = 'RV82'
),

protections as (
select l.cd_ref, nv1.nv1, nv2.nv2, nv3.nv3,rv82.rv82
from liste_p l
left join nv1 on l.cd_ref = nv1.cd_ref
left join nv2 on l.cd_ref = nv2.cd_ref
left join nv3 on l.cd_ref = nv3.cd_ref
left join rv82 on l.cd_ref = rv82.cd_ref
)

--select type_geom,count(*) as nb from (
select 

s.unique_id_sinp,
s.unique_id_sinp_grp,
s.date_min::TIMESTAMP::DATE AS date_debut,
s.date_max::TIMESTAMP::DATE AS date_fin,
s.observers,
t.cd_ref,
t.nom_valide,
n.label_default AS niveau_validation,
p.nv1,
p.nv2,
p.nv3,
p.rv82,
--s.the_geom_local,
n1.label_default as nature_objet,
s."precision",
st_geometrytype(s.the_geom_local) as type_geom,
case 
	when st_geometrytype(s.the_geom_local)in ('ST_MultiPoint','ST_Point') then st_buffer(s.the_geom_local,s."precision")
	when st_geometrytype(s.the_geom_local) in ('ST_LineString','ST_MultiLineString') then st_buffer(s.the_geom_local,2,10)
	else s.the_geom_local
end as geom,
case 
	when st_geometrytype(s.the_geom_local)in ('ST_MultiPoint','ST_Point') then s."precision"
	else width(box(s.the_geom_local))
end as horizontal,
case 
	when st_geometrytype(s.the_geom_local)in ('ST_MultiPoint','ST_Point') then s."precision"
	else height(box(s.the_geom_local))
end as vertical,

case 
	when st_geometrytype(s.the_geom_local)in ('ST_MultiPoint','ST_Point') then pi()*s."precision"*s."precision"
	when st_geometrytype(s.the_geom_local)in ('ST_LineString','ST_MultiLineString') then st_area(st_buffer(s.the_geom_local,2,10))
	else st_area(s.the_geom_local)
end as surfm2,

c.unique_acquisition_framework_id AS ca_uuid,
c.acquisition_framework_name AS ca_nom,
j.unique_dataset_id AS jdd_uuid,
j.dataset_name AS jdd_nom

from gn_synthese.synthese s 
join taxonomie.taxref t on s.cd_nom = t.cd_nom 
join protections p on t.cd_ref = p.cd_ref
join gn_synthese.cor_area_synthese cas on s.id_synthese = cas.id_synthese 
join ref_geo.l_areas la on cas.id_area = la.id_area 
JOIN gn_meta.t_datasets AS j ON s.id_dataset = j.id_dataset
JOIN gn_meta.t_acquisition_frameworks AS c ON c.id_acquisition_framework = j.id_acquisition_framework
JOIN ref_nomenclatures.t_nomenclatures AS n ON s.id_nomenclature_valid_status = n.id_nomenclature  
JOIN ref_nomenclatures.t_nomenclatures AS n1 ON s.id_nomenclature_geo_object_nature = n1.id_nomenclature
where la.area_code = '73'
--and st_geometrytype(s.the_geom_local)= 'ST_MultiPoint'
--) as table1
--group by type_geom
;
