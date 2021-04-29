# FLAVIA DATA

## Import des données

* Si nécessaire, copier/coller le fichier `shared/config/settings.sample.ini` 
en le renomant `shared/config/settings.ini`.
    * Modifier dans ce fichier les paramètres de connexion à votre base de données GeoNature.
* Si nécessaire, copier/coller le fichier `flavia/config/settings.sample.ini` 
en le renomant `flavia/config/settings.ini`.
    * Adapter à votre installation les paramètres présents dans ce fichier. Si 
    nécessaire, vous pouvez aussi y surcharger des paramètres du fichier  
    `flavia/config/settings.default.ini`.
* Se placer dans le dossier `flavia/bin/` et utiliser le script 
`./import_initial.sh -v` pour importer le jeu de données de FLAVIA.
    * Le script se charge de télécharger les données brutes depuis Dropbox
    * Les scripts SQL du dossier `flavia/data/sql/initial/` seront ensuite exécutés séquentiellement.

## Synchronisation serveur

Pour transférer uniquement le dossier `flavia/` sur le serveur, utiliser `rsync` 
en testant avec l'option `--dry-run` (à supprimer quand tout est ok):

```shell
rsync -av --copy-unsafe-links \
    --exclude var \
    --exclude .gitignore \
    --exclude settings.ini \
    --exclude "data/raw/*" \
    ./ geonat@db-aura-sinp:~/data/flavia/ --dry-run
```

## Création de l'archive sur Dropbox

L'archive au format d'échange doit être stocké sur Dropbox au niveau du dossier 
`Applications/data-aura-sinp/flavia`.
Elle doit être compressé au format `.tar.bz2` pour cela se placer dans le
dossier contenant les fichiers `.csv` du format d'échange et lancer la commande :
```
tar jcvf ../2021-03-31_sinp_aura_flavia.tar.bz2 .
```

## Commandes appliquées

### Fichier synthese.csv export 2021-03-31_sinp_aura_flavia

Liste des corrections appliquées au fichier `synthese.csv` transmis :

```shell

```

Liste des corrections appliquées au fichier `user.csv` transmis :
```shell

```

Liste des corrections appliquées au fichier `dataset.csv` transmis :
```shell

```
