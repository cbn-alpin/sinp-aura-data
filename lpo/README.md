# FLAVIA DATA

## Import des données

* Si nécessaire, copier/coller le fichier `shared/config/settings.sample.ini` 
en le renomant `shared/config/settings.ini`.
    * Modifier dans ce fichier les paramètres de connexion à votre base de données GeoNature.
* Si nécessaire, copier/coller le fichier `lpo/config/settings.sample.ini` 
en le renomant `lpo/config/settings.ini`.
    * Adapter à votre installation les paramètres présents dans ce fichier. Si 
    nécessaire, vous pouvez aussi y surcharger des paramètres du fichier  
    `lpo/config/settings.default.ini`.
* Se placer dans le dossier `lpo/bin/` et utiliser le script 
`./import_initial.sh -v` pour importer le jeu de données de la LPO AURA.
    * Le script se charge de télécharger les données brutes depuis Dropbox
    * Les scripts SQL du dossier `lpo/data/sql/initial/` seront ensuite exécutés séquentiellement.

## Synchronisation serveur

Pour transférer uniquement le dossier `lpo/` sur le serveur, utiliser `rsync` 
en testant avec l'option `--dry-run` (à supprimer quand tout est ok):

```shell
rsync -av --copy-unsafe-links \
    --exclude var \
    --exclude .gitignore \
    --exclude settings.ini \
    --exclude "data/raw/*" \
    ./ geonat@db-aura-sinp:~/data/lpo/ --dry-run
```

## Création de l'archive sur Dropbox

L'archive au format d'échange doit être stocké sur Dropbox au niveau du dossier 
`Applications/data-aura-sinp/lpo`.
Elle doit être compressé au format `.tar.bz2` pour cela se placer dans le
dossier contenant les fichiers `.csv` du format d'échange et lancer la commande :
```
tar jcvf ../2021-03-16_sinp_aura_lpo.tar.bz2 .
```
