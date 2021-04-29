# CBNA DATA

## Import des données

* Si nécessaire, copier/coller le fichier `shared/config/settings.sample.ini` 
en le renomant `shared/config/settings.ini`.
    * Modifier dans ce fichier les paramètres de connexion à votre base de données GeoNature.
* Si nécessaire, copier/coller le fichier `cbna/config/settings.sample.ini` 
en le renomant `cbna/config/settings.ini`.
    * Adapter à votre installation les paramètres présents dans ce fichier. Si 
    nécessaire, vous pouvez aussi y surcharger des paramètres du fichier  
    `cbna/config/settings.default.ini`.
* Se placer dans le dossier `cbna/bin/` et utiliser le script 
`./import_initial.sh -v` pour importer le jeu de données du CBNA.
    * Le script se charge de télécharger les données brutes depuis Dropbox
    * Les scripts SQL du dossier `cbna/data/sql/initial/` seront ensuite exécutés séquentiellement.

## Synchronisation serveur

Pour transférer uniquement le dossier `cbna/` sur le serveur, utiliser `rsync` 
en testant avec l'option `--dry-run` (à supprimer quand tout est ok):

```shell
rsync -av --copy-unsafe-links \
    --exclude var \
    --exclude .gitignore \
    --exclude settings.ini \
    --exclude "data/raw/*" \
    ./ geonat@db-aura-sinp:~/data/cbna/ --dry-run
```

## Création de l'archive sur Dropbox

L'archive au format d'échange doit être stocké sur Dropbox au niveau du dossier 
`Applications/data-aura-sinp/cbna`.
Elle doit être compressé au format `.tar.bz2` pour cela se placer dans le
dossier contenant les fichiers `.csv` du format d'échange et lancer la commande :
```
tar jcvf ../2021-04-15_sinp_aura_cbna.tar.bz2 .
```

## Commandes appliquées

### Fichier synthese.csv export 2021-04-15_sinp_aura_cbna

Liste des corrections appliquées au fichier `synthese.csv` transmis :

```shell

```

Liste des corrections appliquées au fichier `user.csv` transmis :
```shell

```

Liste des corrections appliquées au fichier `dataset.csv` transmis :
```shell

```
