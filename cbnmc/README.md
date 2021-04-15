# CBNMC DATA

## Import des données

* Si nécessaire, copier/coller le fichier `shared/config/settings.sample.ini` 
en le renomant `shared/config/settings.ini`.
    * Modifier dans ce fichier les paramètres de connexion à votre base de données GeoNature.
* Si nécessaire, copier/coller le fichier `cbnmc/config/settings.sample.ini` 
en le renomant `cbnmc/config/settings.ini`.
    * Adapter à votre installation les paramètres présents dans ce fichier. Si 
    nécessaire, vous pouvez aussi y surcharger des paramètres du fichier  
    `cbnmc/config/settings.default.ini`.
* Se placer dans le dossier `cbnmc/bin/` et utiliser le script 
`./import_initial.sh -v` pour importer le jeu de données de test du CEN-PACA.
    * Le script se charge de télécharger les données brutes depuis Dropbox
    * Les scripts SQL du dossier `cbnmc/data/sql/initial/` seront ensuite exécuté séquentiellement.

## Synchronisation serveur

Pour transférer uniquement le dossier `cbnmc/` sur le serveur, utiliser `rsync` 
en testant avec l'option `--dry-run` (à supprimer quand tout est ok):

```
rsync -av --copy-unsafe-links --exclude var --exclude .gitignore --exclude settings.ini --exclude "data/raw/*" ./ geonat@db-aura-sinp:~/data/cbnmc/ --dry-run
```

## Création de l'archive sur Dropbox

L'archive au format d'échange doit être stocké sur Dropbox au niveau du dossier 
`Applications/data-aura-sinp/cbnmc`.
Elle doit être compressé au format `.tar.bz2` pour cela se placer dans le
dossier contenant les fichiers `.csv` du format d'échange et lancer la commande :
```
tar jcvf ../2021-04-09_sinp_aura_cbnmc.tar.bz2 .
```

## Commandes appliquées

### Fichier synthese.csv export 2021-03-16_sinp_aura_cbnmc

Liste des corrections appliquées au fichier `synthese.csv` transmis :

```
# Sur le fichier de 4 millions de lignes nous obenons l'erreur suivant avec sed et l'option -z
# sed: la taille du tampon d'entrée d'expression régulière est plus grand que INT_MAX
# Pour contourner le problème nous découpons le fichier en lot de 2 millions

# Découpage du fichier rsynthese.csv en 2 fichiers de 2 millions de lignes
sed -n '1,2000000 p' synthese.csv > synthese.1.csv
sed -n '2000001,4000000 p' synthese.csv > synthese.2.csv

# Suppression des retours à la ligne
sed -i -z 's/\r\n/\\r\\n/g' synthese.1.csv
sed -i -z 's/\r\n/\\r\\n/g' synthese.2.csv
sed -i -z 's/\(\t"[^"\t\n]*\)\n/\1\\n/g' synthese.1.csv
sed -i -z 's/\(\t"[^"\t\n]*\)\n/\1\\n/g' synthese.2.csv

# Recréation du fichier synthese.csv à partir des 2 fichiers de 2 millions de lignes
cat synthese.2.csv >> synthese.1.csv ; mv synthese.1.csv synthese.csv

# Remplacement des tabulations en trop
sed -i 's#Haut-Beaujolais\t"#Haut-Beaujolais"#g' synthese.csv
sed -i 's#\t\t\\r\\n"#"#g' synthese.csv
sed -i 's#\t\t\\r\\n"#"#g' synthese.csv
sed -i 's#\t*\\r\\n##g' synthese.csv
sed -i 's#"\t*\s*Saisie#"Saisie#g' synthese.csv

```

Liste des corrections appliquées au fichier `user.csv` transmis :
```
sed -i -z 's/\r\n/\\r\\n/g' user.csv
```

Liste des corrections appliquées au fichier `dataset.csv` transmis :
```
sed -i -z 's/\r\n/\\r\\n/g' dataset.csv
```
