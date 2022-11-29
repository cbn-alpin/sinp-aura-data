select distinct s.cd_nom, t.nom_complet ,t.cd_ref ,t.nom_valide ,t.regne
from gn_synthese.synthese s
--join ref_geo.l_areas l on st_intersects(s.the_geom_local,l.geom)
join ref_geo.l_areas l on st_within(st_transform(s.the_geom_point,2154),l.geom)
join taxonomie.taxref t on s.cd_nom = t.cd_nom 
where l.area_code ='38'
order by t.nom_valide 
