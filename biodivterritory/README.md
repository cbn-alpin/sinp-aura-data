# Biodiv'Territoire

## Installation de Biodiv'Territoire en base de données

Appliquer successivement les 5 fichiers SQL dans l'ordre (01_..., 02_..., etc) du dossier `sql` :
```bash
psql -U geonatadmin -h localhost geonature2db -f data/sql/install/01_taxonomy_schema.sql
```
### Schéma `taxonomie`

- Nouvelles tables dédiées à la gestion des listes rouges:
  - `taxonomie.bib_c_redlist_categories` > Liste des catégories de statuts de liste rouge
  - `taxonomie.bib_c_redlist_source` > Liste des sources de liste rouge
  - `taxonomie.cor_c_redlist_source_area` > Correlation between RedList sources (bib_c_redlist_source) and areas (ref_geo.l_areas) : defines where Red List sources apply.
  - `taxonomie.t_c_redlist` > Liste des sources de statuts de liste rouge

### Schéma `gn_biodivterritory`

- Tables et vues matérialisées dédiées à l'application biodiv-territoires
- **!!! Adaptation a faire dans le fichier 05 sur la liste des area_type à utiliser (INSERT sur la table `gn_biodivterritory.l_areas_type_selection`). notamment les mailles utilisées pour la restitution carto. Pour les EPCI, il faut les ajouter dans le ref_geo si attendu**

## Syncrhoniser le serveur

Pour transférer les données sur le serveur, utiliser Rsync :
```bash
rsync -av biodivterritory geonat@db-aura-sinp:/home/geonat/data/ --dry-run
```
Supprimer l'option `--dry-run` si tout semble OK.
