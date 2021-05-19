# Gestion de la mise à jour / adaptation de l'Atlas

Contient les fichiers SQL à éxecuter sur l'instance `db-srv` pour adapter 
la base de GeoNature Atlas vis à vis de l'instalation pour le 
SINP AURA.

## Mise à jour de la VM `atlas.vm_observations`

Mise à jour de la VM `atlas.vm_observations` afin qu'elle utilise une VM `atlas.t_subdivided_territory`.
Cette dernière VM contient les polygones correspondant à la subdivision du territoire
à l'aide de la fonction Postgis `st_subdivide()`.
La mise à jour de la VM `atlas.vm_observations` prend environs 5 mn pour 5 millions d'observations
dans la synthèse contre plusieurs heures avec l'ancien mécanisme.

## Synchronisation serveur

Pour transférer uniquement le dossier `db-atlas/` sur le serveur, utiliser `rsync` 
en testant avec l'option `--dry-run` (à supprimer quand tout est ok):

```bash
rsync -av --copy-unsafe-links ./ geonat@db-aura-sinp:~/data/db-atlas/ --dry-run
```


## Exécution du SQL

Se placer dans le dossier `db-atlas/` et utiliser les commandes :
```bash
source ../shared/config/settings.default.ini
source ../shared/config/settings.ini
psql -h "${db_host}" -U "${db_user}" -d "gnatlas" -f ./data/sql/01_update_vm_observations.sql
```
