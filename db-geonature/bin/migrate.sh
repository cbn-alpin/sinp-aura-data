#!/bin/bash
# Encoding : UTF-8
# Merge DB GeoNature users ids


#+----------------------------------------------------------------------------------------------------------+
# Configure script execute options
set -euo pipefail

# DESC: Usage help
# ARGS: None
# OUTS: None
function printScriptUsage() {
    cat << EOF
Usage: ./$(basename $BASH_SOURCE)[options]
     -h | --help: display this help
     -v | --verbose: display more infos
     -x | --debug: display debug script infos
     -c | --config: path to config file to use (default : config/settings.ini)
EOF
    exit 0
}

# DESC: Parameter parser
# ARGS: $@ (optional): Arguments provided to the script
# OUTS: Variables indicating command-line parameters and options
function parseScriptOptions() {
    # Transform long options to short ones
    for arg in "${@}"; do
        shift
        case "${arg}" in
            "--help") set -- "${@}" "-h" ;;
            "--verbose") set -- "${@}" "-v" ;;
            "--debug") set -- "${@}" "-x" ;;
            "--config") set -- "${@}" "-c" ;;
            "--"*) exitScript "ERROR : parameter '${arg}' invalid ! Use -h option to know more." 1 ;;
            *) set -- "${@}" "${arg}"
        esac
    done

    while getopts "hvxc:i:o:" option; do
        case "${option}" in
            "h") printScriptUsage ;;
            "v") readonly verbose=true ;;
            "x") readonly debug=true; set -x ;;
            "c") setting_file_path="${OPTARG}" ;;
            *) exitScript "ERROR : parameter invalid ! Use -h option to know more." 1 ;;
        esac
    done
}

# DESC: Main control flow
# ARGS: $@ (optional): Arguments provided to the script
# OUTS: None
function main() {
    #+----------------------------------------------------------------------------------------------------------+
    # Load utils
    source "$(dirname "${BASH_SOURCE[0]}")/../../shared/lib/utils.bash"

    #+----------------------------------------------------------------------------------------------------------+
    # Init script
    initScript "${@}"
    parseScriptOptions "${@}"
    loadScriptConfig "${setting_file_path-}"
    redirectOutput "${dbgn_log_file}"

    #+----------------------------------------------------------------------------------------------------------+
    # Start script
    printInfo "${app_name} migrate script started at: ${fmt_time_start}"

    local backup_db_name="${dbgn_db_destination_name}_backup"

    insertUtilsFunctionsToSrcDb
    exportCsvFilesFromSourceDb
    if isDbExists "${backup_db_name}"; then
        restoreDestinationDbFromBackup
        backupDefaultDataFromDestinationDb
        insertUtilsFunctionsToDestinationDb
    else
        backupDestinationDb "${backup_db_name}"
    fi
    initializeDestinationDb
    restoreDefaultDataToDestinationDb
    importCsvFilesToDestinationDb
    cleanRefGeoInDestinationDb
    cleanUsersInDestinationDb
    executeSqlScripts

    #+----------------------------------------------------------------------------------------------------------+
    # Display script execution infos
    displayTimeElapsed
}

function insertUtilsFunctionsToSrcDb() {
    printMsg "Insert utils functions into source database..."

    PGPASSWORD="${dbgn_db_source_password}" psql \
        -h "${dbgn_db_source_host}" -p "${dbgn_db_source_port}" \
        -U "${dbgn_db_source_user}" -d "${dbgn_db_source_name}" \
        -f "${sql_shared_dir}/utils_functions.sql"
}

function exportCsvFilesFromSourceDb() {
    printMsg "Export to CSV files data from source database..."

    exportCsvFromSrc "ref_geo.bib_areas_types"
    exportCsvFromSrc "ref_geo.l_areas" "id_area, id_type, area_name, area_code, geom, centroid, source, comment, enable, additional_data, meta_create_date, meta_update_date, geom_4326, description"
    exportCsvFromSrc "ref_geo.li_grids"
    exportCsvFromSrc "ref_geo.li_municipalities"

    exportCsvFromSrcByQuery "utilisateurs.bib_organismes" \
        "SELECT
            uuid_organisme,
            nom_organisme,
            adresse_organisme,
            cp_organisme,
            ville_organisme,
            tel_organisme,
            fax_organisme,
            email_organisme,
            url_organisme,
            url_logo,
            additional_data,
            now() AS meta_create_date,
            now() AS meta_update_date
        FROM utilisateurs.bib_organismes
        ORDER BY id_organisme"

    exportCsvFromSrcByQuery "utilisateurs.t_roles" \
        "SELECT
            groupe,
            uuid_role,
            identifiant,
            nom_role,
            prenom_role,
            desc_role,
            pass,
            pass_plus,
            email,
            remarques,
            active,
            jsonb_set(
                COALESCE(champs_addi, '{}'::jsonb),
                '{migrate2026}',
                jsonb_build_object(
                    'idOrganismSrc', id_organisme,
                    'idRoleSrc', id_role
                )
            ) AS champs_addi,
            date_insert,
            date_update
        FROM utilisateurs.t_roles
        ORDER BY groupe, id_role"

    exportCsvFromSrcByQuery "utilisateurs.tmp_cor_roles" \
        "SELECT
            utilisateurs.get_uuid_by_id_role(id_role_utilisateur) AS uuid_utilisateur,
            utilisateurs.get_uuid_by_id_role(id_role_groupe) AS uuid_groupe
        FROM utilisateurs.cor_roles"

    exportCsvFromSrcByQuery "utilisateurs.tmp_cor_role_token" \
        "SELECT
            utilisateurs.get_uuid_by_id_role(id_role) AS uuid_role,
            token
        FROM utilisateurs.cor_role_token"
}

function exportCsvFromSrc() {
    local schema_table="${1}"
    local fields=$([ -z "${2:-}" ] && echo "" || echo "($2)")
    local csv_filename="${schema_table//./_}"
    local output="${raw_dir}/${csv_filename}.csv"

    printInfo "Export CSV for table ${schema_table} from SRC DB"

    PGPASSWORD="${dbgn_db_source_password}" psql -AXqt \
        -h "${dbgn_db_source_host}" -p "${dbgn_db_source_port}" \
        -U "${dbgn_db_source_user}" -d "${dbgn_db_source_name}" \
        -c "\COPY ${schema_table} ${fields} TO STDOUT WITH CSV HEADER DELIMITER E'\t'" > "${output}"
    printVerbose "${output} file created"
}

function exportCsvFromSrcByQuery() {
    local csv_filename="${1//./_}"
    local query="${2}"
    local output="${raw_dir}/${csv_filename}.csv"

    printInfo "Export ${csv_filename} by query from SRC DB"

    PGPASSWORD="${dbgn_db_source_password}" psql -AXqt \
        -h "${dbgn_db_source_host}" -p "${dbgn_db_source_port}" \
        -U "${dbgn_db_source_user}" -d "${dbgn_db_source_name}" \
        -c "\COPY (${query}) TO STDOUT WITH CSV HEADER DELIMITER E'\t'" > "${output}"
    printVerbose "${output} file created"
}

function isDbExists() {
    local db_name="${1}"

    if executeSuperAdminPsqlOnDst "-lqt" | grep -qw "${db_name}"; then
        printVerbose "Database '${db_name}' already exists."
        return 1 # Explicitly return 1 for success
    else
        printVerbose "Database '${db_name}' does not exist."
        return 0 # Explicitly return 0 for failure
    fi
}

function executeSuperAdminPsqlOnDst() {
    local psql_command="${1}"

    PGPASSWORD="${dbgn_db_destination_superadmin_password}" psql \
        -h "${dbgn_db_destination_host}" -p "${dbgn_db_destination_port}" \
        -U "${dbgn_db_destination_superadmin_name}" \
        ${psql_command}
}

function restoreDestinationDbFromBackup() {
    printMsg "Restore destination database ${dbgn_db_destination_name} from backup template DB..."
    local backup_db_name="${dbgn_db_destination_name}_backup"

    executeSuperAdminQueryOnDst "SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE pg_stat_activity.datname = '${backup_db_name}' AND pid <> pg_backend_pid();"
    executeSuperAdminQueryOnDst "SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE pg_stat_activity.datname = '${dbgn_db_destination_name}' AND pid <> pg_backend_pid();"

    printInfo "Dropping destination database '${dbgn_db_destination_name}'..."
    executeSuperAdminQueryOnDst "DROP DATABASE IF EXISTS ${dbgn_db_destination_name} ;"

    printInfo "Restoring destination database '${dbgn_db_destination_name}' from backup '${backup_db_name}'..."
    executeSuperAdminQueryOnDst "CREATE DATABASE ${dbgn_db_destination_name} WITH TEMPLATE ${backup_db_name} ;"
}

function backupDefaultDataFromDestinationDb() {
    printMsg "Export to CSV files default data from destination database..."

    exportCsvFromDst "gn_commons.t_parameters" "parameter_name, parameter_desc, parameter_value, parameter_extra_value"
    exportCsvFromDst "gn_notifications.t_notifications_rules" "code_method, code_category, subscribed"
    exportCsvFromDst "gn_synthese.defaults_nomenclatures_value"
    exportCsvFromDst "ref_nomenclatures.defaults_nomenclatures_value"
}

function exportCsvFromDst() {
    local schema_table="${1}"
    local fields=$([ -z "${2:-}" ] && echo "" || echo "($2)")
    local csv_filename="${schema_table//./_}"
    local output="${raw_dir}/${csv_filename}.csv"

    printInfo "Export CSV for table ${schema_table} from DST DB"

    PGPASSWORD="${dbgn_db_destination_password}" psql -AXqt \
        -h "${dbgn_db_destination_host}" -p "${dbgn_db_destination_port}" \
        -U "${dbgn_db_destination_user}" -d "${dbgn_db_destination_name}" \
        -c "\COPY ${schema_table} ${fields} TO STDOUT WITH CSV HEADER DELIMITER E'\t'" > "${output}"
    printVerbose "${output} file created"
}

function insertUtilsFunctionsToDestinationDb() {
    printMsg "Insert utils functions into destination database..."

    PGPASSWORD="${dbgn_db_destination_password}" psql \
        -h "${dbgn_db_destination_host}" -p "${dbgn_db_destination_port}" \
        -U "${dbgn_db_destination_user}" -d "${dbgn_db_destination_name}" \
        -f "${sql_shared_dir}/utils_functions.sql"
}

function backupDestinationDb() {
    local backup_db_name="${1}"

    printMsg "Backup destination database ${dbgn_db_destination_name} to ${backup_db_name} template..."

    executeSuperAdminQueryOnDst "SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE pg_stat_activity.datname = '${dbgn_db_destination_name}' AND pid <> pg_backend_pid();"
    executeSuperAdminQueryOnDst "CREATE DATABASE ${backup_db_name} WITH TEMPLATE ${dbgn_db_destination_name} ;"
}

function executeSuperAdminQueryOnDst() {
    local sql_query="${1}"

    PGPASSWORD="${dbgn_db_destination_superadmin_password}" psql \
        -h "${dbgn_db_destination_host}" -p "${dbgn_db_destination_port}" \
        -U "${dbgn_db_destination_superadmin_name}" \
        -c "${sql_query}"
}

function initializeDestinationDb()  {
    printMsg "Initialize destination database..."

    executeSqlFile "000a_initialize_destination_db.sql"
}

function restoreDefaultDataToDestinationDb() {
    printMsg "Restore default data to destination database..."

    executeQuery "INSERT INTO utilisateurs.bib_organismes (id_organisme, uuid_organisme, nom_organisme) VALUES
        ('2', 'e101b223-1354-4388-bdf9-cec5b189985e'::uuid, 'ALL (temp)');"

    importCsvToDst "gn_commons.t_parameters" "parameter_name, parameter_desc, parameter_value, parameter_extra_value"
    importCsvToDst "gn_notifications.t_notifications_rules" "code_method, code_category, subscribed"
    importCsvToDst "gn_synthese.defaults_nomenclatures_value"
    importCsvToDst "ref_nomenclatures.defaults_nomenclatures_value"
}

function importCsvFilesToDestinationDb() {
    printMsg "Import to destination database the CSV files..."

    importCsvToDst "ref_geo.bib_areas_types"
    importCsvToDst "ref_geo.l_areas"
    importCsvToDst "ref_geo.li_grids"
    importCsvToDst "ref_geo.li_municipalities"

    importCsvToDst "utilisateurs.bib_organismes" "uuid_organisme, nom_organisme, adresse_organisme, cp_organisme, ville_organisme, tel_organisme, fax_organisme, email_organisme, url_organisme, url_logo, additional_data, meta_create_date, meta_update_date"
    importCsvToDst "utilisateurs.t_roles" "groupe, uuid_role, identifiant, nom_role, prenom_role, desc_role, pass, pass_plus, email, remarques, active, champs_addi, date_insert, date_update"

    importCorRolesCsvToDst
    importCorRoleTokenCsvToDst
}

function importCsvToDst() {
    local schema_table="${1}"
    local fields=$([ -z "${2:-}" ] && echo "" || echo "($2)")
    local csv_filename="${schema_table//./_}"
    local input="${raw_dir}/${csv_filename}.csv"

    printInfo "Import CSV to table ${schema_table}"

    PGPASSWORD="${dbgn_db_destination_password}" psql \
        -h "${dbgn_db_destination_host}" -p "${dbgn_db_destination_port}" \
        -U "${dbgn_db_destination_user}" -d "${dbgn_db_destination_name}" \
        -c "\COPY ${schema_table} ${fields} FROM STDIN WITH CSV HEADER DELIMITER E'\t'" < "${input}"

    printVerbose "Data loaded into ${schema_table} from ${input} file"
}

function importCorRolesCsvToDst() {
    printInfo "Import CSV to table utilisateurs.cor_roles"

    executeQuery "CREATE TABLE utilisateurs.tmp_cor_roles (
            uuid_utilisateur UUID,
            uuid_groupe UUID
        );"
    importCsvToDst "utilisateurs.tmp_cor_roles"
    executeQuery "INSERT INTO utilisateurs.cor_roles (id_role_utilisateur, id_role_groupe)
        SELECT
            utilisateurs.get_id_role_by_uuid(t.uuid_utilisateur) AS id_role_utilisateur,
            utilisateurs.get_id_role_by_uuid(t.uuid_groupe) AS id_role_groupe
        FROM utilisateurs.tmp_cor_roles AS t;"
    executeQuery "DROP TABLE utilisateurs.tmp_cor_roles"
}

function importCorRoleTokenCsvToDst() {
    printInfo "Import CSV to table utilisateurs.cor_role_token"

    executeQuery "CREATE TABLE utilisateurs.tmp_cor_role_token (
            uuid_role UUID,
            token TEXT
        );"
    importCsvToDst "utilisateurs.tmp_cor_role_token"
    executeQuery "INSERT INTO utilisateurs.cor_role_token (id_role, token)
        SELECT
            utilisateurs.get_id_role_by_uuid(t.uuid_role) AS id_role,
            t.token
        FROM utilisateurs.tmp_cor_role_token AS t;"
    executeQuery "DROP TABLE utilisateurs.tmp_cor_role_token"
}

function executeQuery() {
    local query="${1}"

    printInfo "\nExecute SQL query on destination database"

    PGPASSWORD="${dbgn_db_destination_password}" psql \
        -h "${dbgn_db_destination_host}" -p "${dbgn_db_destination_port}" \
        -U "${dbgn_db_destination_user}" -d "${dbgn_db_destination_name}" \
        -c "${query}"
}

function cleanRefGeoInDestinationDb()  {
    printMsg "Clean ref geo data in destination database..."

    executeSqlFile "000b_clean_ref_geo_data.sql"
}

function cleanUsersInDestinationDb()  {
    printMsg "Clean users data in destination database..."

    executeSqlFile "000c_clean_users_data.sql"
}

function executeSqlScripts() {
    printMsg "Execute SQL scripts to update destination database..."

    # TODO: update SQL code for this SQL scripts
    executeSqlFile "001_replace_synthese_export_view.sql"
    executeSqlFile "002_replace_synthese_profile_view.sql"
    executeSqlFile "003_disable_status_text.sql"
    executeSqlFile "004_populate_bdc_statut_cor_text_area.sql"
    executeSqlFileWithInterpolatedVar "005_add_new_sensitivity_nomenclatures.sql"
    executeSqlFile "006_disable_permanently_sensitivity_triggers.sql"
    executeSqlFileWithInterpolatedVar "007_add_forest_flora_taxhub_attribut.sql"
    executeSqlFileWithInterpolatedVar "008_add_taxa_lists_taxhub_attribut.sql"
    executeSqlFile "009_update_sensitivity_area.sql"
    executeSqlFile "010_create_vm_for_synthese_export.sql"
    executeSqlFile "011_add_values_to_campanule_nomenclature.sql"
    executeSqlFile "012_updates_for_atlas_2.sql"
    executeSqlFileWithInterpolatedVar "013_add_invasive_species_taxhub_attribut.sql"
}

function executeSqlFile() {
    local sql_script="${1}"

    printInfo "\nExecute SQL script ${sql_script} on destination database"

    local output
    output=$(PGPASSWORD="${dbgn_db_destination_password}" psql \
        -h "${dbgn_db_destination_host}" -p "${dbgn_db_destination_port}" \
        -U "${dbgn_db_destination_user}" -d "${dbgn_db_destination_name}" \
        -f "${sql_dir}/${sql_script}" 2>&1 | tee /dev/tty)

    analyseSqlExecutionOutput "${output}" "${sql_script}"
}

function executeSqlFileWithInterpolatedVar() {
    local sql_script="${1}"

    printInfo "\nExecute SQL script ${sql_script} with interpolated variables on destination database"

    local output
    output=$({
        cat "${sql_dir}/${sql_script}" | \
        sed "s#\${csvDirectory}#${data_dir}/csv#g" | \
        PGPASSWORD="${dbgn_db_destination_password}" psql \
            -h "${dbgn_db_destination_host}" -p "${dbgn_db_destination_port}" \
            -U "${dbgn_db_destination_user}" -d "${dbgn_db_destination_name}"
    } 2>&1 | tee /dev/tty)

    analyseSqlExecutionOutput "${output}" "${sql_script}"
}

function analyseSqlExecutionOutput() {
    local output="${1}"
    local sql_script="${2}"

    # Check for ROLLBACK or COMMIT in the output
    if echo "${output}" | grep -q -E "^(ROLLBACK|FATAL|ERROR)"; then
        printError "SQL script ${sql_script} failed and was rolled back."
        exitScript "Migration script aborted due to SQL error." 1
    elif echo "${output}" | grep -q -E "^COMMIT$"; then
        printInfo "${Gre}SQL script ${sql_script} executed successfully.${RCol}"
    else
        printPretty "SQL script ${sql_script} execution status unknown." ${Yel}
    fi
}

main "${@}"
