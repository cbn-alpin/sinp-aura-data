# Gn2Pg

Installation de [GN2PG](https://github.com/lpoaura/GN2PG) spécifique au SINP AURA.

## Installation de Pipenv

Sous Debian Buster :
```bash
cd gn2pg/
pip3 install --user pipenv
```

- Ajouter le code suivant au fichier `~/.bashrc` :
```
# Add ~/.local/bin to PATH (Pipenv)
if [ -d "${HOME}/.local/bin" ] ; then
    PATH="${HOME}/.local/bin:$PATH"
fi
```
- Recharger le fichier `~/.bashrc` avec la commande : `source ~/.bashrc`
- **Notes** : il est nécessaire de donner les droits d'execution à GCC pour
tout le monde si l'on veut pouvoir installer correctement le venv
avec `sudo chmod o+x /usr/bin/gcc`. Une fois l'installation terminée,
retirer les à nouveau avec  `sudo chmod o-x /usr/bin/gcc`.

Pour créer un fichier Pipfile avec le paquet `gn2pg-client` utiliser :
```bash
pipenv install gn2pg-client
```

## Mise en place

- Installer les dépendances le venv et ses dépendances via :
  - `cd gn2pg/`
  - `pipenv install`
- Créer un lien symbolique du dossier ~/.gn2pg/ vers le dossier config/ :
    ```bash
    ln -s ~/data/gn2pg/config ~/.gn2pg
    ```
- Créer vos fichiers `..._config.toml` à partir des exemples :
    ```bash
    cp ~/data/gn2pg/config/..._config.sample.toml ~/data/gn2pg/config/..._config.toml
    ```
- Adapter les fichiers `..._config.toml` à votre installation.
- Vérifier la version et le fonctionnement de GN2PG :
    ```bash
    pipenv run gn2pg_cli --help
    ```
- Générer les schémas et les tables de GN2PG :
    ```bash
    pipenv run gn2pg_cli --json-tables-create <my-config-file>
    ```
    - Exemple :
        ```bash
        pipenv run gn2pg_cli --json-tables-create lpo_config.toml
        ```
- Executer ensuite les fichiers `sql/..._to_synthese.sql` correspondant à vos besoins :
    ```bash
    pipenv run gn2pg_cli --custom-script ~/data/gn2pg/data/sql/..._to_synthese.sql <my-config-file>
    ```
    - Exemple :
        ```bash
        pipenv run gn2pg_cli --custom-script ./data/sql/lpo_to_synthese.sql lpo_config.toml
        ```
- Si nécessaire, supprimer les données préalablement stocker dans la base. Ex. :
```bash
psql -h localhost -U geonatadmin -d geonature2db -f ~/data/lpo/data/sql/update/001_delete_all_lpo_data.sql
```
- En local, se placer sur un terminal natif : `CTRL+ALT+F1`
- Lancer un session Screen :
    ```bash
    screen -S <nom-de-la-session>
    ```
    - Example :
        ```bash
        screen -S gn2pg-lpo
        ```
- Lancer le téléchargement complet :
    ```bash
    pipenv run gn2pg_cli --full <my-config-file>
    ```
    - Exemple :
        ```bash
        pipenv run gn2pg_cli --full lpo_config.toml
        ```

## Utiliser gn2pg

- Lancer une seule commande : `pipenv run gn2pg_cli --help`
- Lancer plusieurs commandes :
  - Activer l'environnement virtuel : `pipenv shell`
  - Lancer ensuite les commandes : `gn2pg_cli --help`
  - Pour désactiver l'environnement virtuel :
  `exit` (`deactivate` ne fonctionne pas avec `pipenv`)

### Relancer une récupération compléte des données depuis un id_synthese spécifique

- Ajouter un paramètre dans le fichier de config dans `[[source]]` au niveau de la sous-section `[source.query_strings]`. Ex. :
    ```ini
    [source.query_strings]
    orderby = "id_synthese"
    filter_n_up_id_synthese = 5840000
    ```
- Note : il faut utiliser le paramètre "`filter_n_up_id_synthese`" avec "`..._n_...`" car "`..._d_...`" c'est pour les champs de type "datetime". Ici, l'id_synthese étant un entier, il faut utiliser le type numérique "`..._n_...`".
- Dans l'exemple ci-dessus, nous repartons depuis l'id_synthese `5840000`. Grâce aux log, nous pouvons trouver l'offset 179 et l'incrément (=limit) de 10 000.
- La requête suivante permet de trouver l'id_synthese supérieur à la 1 790 000ème observations :
    ```sql
    SELECT * FROM gn2pg_flavia.data_json ORDER BY id_data ASC OFFSET 1790000 LIMIT 10000 ;
    ```


## Tansfert d'un schéma gn2pg en production

Exemple avec LPO :
- Localement, attendre d'avoir récupérer toutes les données via la commande : `pipenv run gn2pg_cli --full lpo_config.toml`
- Localement, créer une archive du schéma `gn2pg_lpo` pour la restaurer en production :
```bash
pg_dump -U geonatadmin -h localhost -d gn2_dev_sinp -n gn2pg_lpo --format=c --compress=9 --file="$(date --iso-8601=date)_gn2pg_lpo.custom"
```
- Transférer l'archive sur le serveur SFTP :
```bash
sftp -oStrictHostKeyChecking=no -oPort="<port-ssh>" "data@51.195.232.41:/lpo/"
sftp> put "2022-05-24_gn2pg_lpo.custom"
sftp> exit
```
- Se connecter sur le serveur DB : `ssh geonat@db-aura-sinp`
- Se placer dans le dossier data/gn2pg/data/raw/ : `cd ~/data/gn2pg/data/raw/`
- Télécharger l'archive à partir du serveur SFTP :
```bash
sftp -oStrictHostKeyChecking=no -oPort="<port-ssh>" "data@51.195.232.41:/lpo/2022-05-24_gn2pg_lpo.custom" "2022-05-24_gn2pg_lpo.custom"
```
- Restaurer le schéma en production :
```bash
psql -U geonatadmin -h localhost -d geonature2db -c "CREATE SCHEMA IF NOT EXISTS gn2pg_lpo AUTHORIZATION geonatadmin;"
pg_restore -U geonatadmin -h localhost -d geonature2db -n gn2pg_lpo --format=c --jobs 6 "$(date --iso-8601=date)_gn2pg_lpo.custom"
```
- Relancer le script `lpo_to_synthese.sql` avec : `pipenv run gn2pg_cli --custom-script ./data/sql/lpo_to_synthese.sql lpo_config.toml`
    - Ou executer les élements non présent dans le schéma gn2pg_lpo :
```sql
ALTER TABLE gn_synthese.synthese DISABLE TRIGGER tri_update_calculate_sensitivity ;

ALTER TABLE gn_synthese.synthese DISABLE TRIGGER tri_insert_calculate_sensitivity ;

CREATE UNIQUE INDEX IF NOT EXISTS uidx_synthese_id_source_id_entity_source_pk_value
    ON gn_synthese.synthese (id_source, entity_source_pk_value) ;

CREATE UNIQUE INDEX IF NOT EXISTS uidx_t_roles_uuid_role
    ON utilisateurs.t_roles (uuid_role) ;
```
- Lancer une session Screen : `screen -S gn2pg-lpo`
- Supprimer les données LPO en production et lancer la mise à jour des triggers :
```bash
psql -h localhost -U geonatadmin -d geonature2db -f ~/data/lpo/data/sql/update/001_delete_all_lpo_data.sql
```
- Si la mise à jour des triggers nécessite d'être forcé, utiliser :
```bash
psql -U geonatadmin -h localhost -d geonature2db -c "BEGIN; UPDATE gn2pg_lpo.data_json SET id_data = id_data; COMMIT;"
```

## Synchronisation serveur

Pour transférer uniquement le dossier `gn2pg/` sur le serveur, se placer dans le dossier puis utiliser `rsync` en testant avec l'option `--dry-run` (à supprimer quand tout est ok):

```bash
rsync -av --copy-unsafe-links --exclude .venv --exclude data/raw/  --exclude config/log/ --exclude *_config.toml --exclude .gitignore ./ geonat@<ip-serveur>:~/data/gn2pg/ --dry-run
```
