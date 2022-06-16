# Gestion de la mise à jour / adaptation de GeoNature

Contient les fichiers SQL à éxecuter sur l'instance `db-srv` pour adapter
la base de données de GeoNature vis à vis de l'instalation pour le
SINP AURA.

## Synchronisation serveur

Pour transférer uniquement le dossier `db-geonature/` sur le serveur, utiliser `rsync`
en testant avec l'option `--dry-run` (à supprimer quand tout est ok):

```bash
rsync -av --copy-unsafe-links --exclude data/raw/* --exclude var ./ geonat@db-aura-sinp:~/data/db-geonature/
```

## Exécution du SQL

Se placer dans le dossier `db-geonature/` et utiliser les commandes :
```bash
source ../shared/config/settings.default.ini
source ../shared/config/settings.ini
psql -h "${db_host}" -U "${db_user}" -d "${db_name}" -f ./data/sql/01_update_modules.sql
```
