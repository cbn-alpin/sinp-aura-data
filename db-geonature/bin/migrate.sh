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
    runChecks

    #+----------------------------------------------------------------------------------------------------------+
    # Start script
    printInfo "🚀 ${app_name} migrate script started at: ${fmt_time_start}"

    local backup_db_name="${dbgn_db_destination_name}_backup"
    local is_db_exists=$(isDbExists "${backup_db_name}")

    insertUtilsFunctionsToSrcDb
    fixSourceDb
    exportCsvFilesFromSourceDb
    if [[ "${is_db_exists}" == "true" ]]; then
        restoreDestinationDbFromBackup
    else
        backupDestinationDb "${backup_db_name}"
    fi
    backupDefaultDataFromDestinationDb
    insertUtilsFunctionsToDestinationDb
    initializeDestinationDb
    restoreDefaultDataToDestinationDb

    importCsvFilesToDestinationDb
    cleanRefGeoInDestinationDb
    cleanUsersInDestinationDb
    addPermissions

    executeSqlScripts

    migratePermissionRequests

    transfertExportModuleTables
    executeExportModuleScripts

    transfertFlaviaGn2PgSchema
    cleanFlaviaGn2Pg
    insertFlaviaGn2PgDataToGN

    transfertLpoGn2PgSchema
    cleanLpoGn2Pg
    insertLpoGn2PgDataToGN

    insertCbnaDataToGN
    insertCbnmcDataToGN

    reloadObservationsAreasLinks

    startMaintenanceTask

    #+----------------------------------------------------------------------------------------------------------+
    # Display script execution infos
    displayTimeElapsed
}

function runChecks {
    local readonly commands=("jo" "jq" "ssh" "psql" "pg_dump" "pg_restore" "tee" "sed")
    checkBinary "${commands[@]}"
}

function insertUtilsFunctionsToSrcDb() {
    printMsg "Insert utils functions into source database..."

    executeSqlFileOnSrcDb "${sql_shared_dir}" "utils_functions.sql"
}

function fixSourceDb()  {
    printMsg "Fix errors in source database..."

    executeSqlFileOnSrcDb "${dbgn_sql_migrate_dir}" "010_fix_source_db.sql"
}

function executeSqlFileOnSrcDb() {
    local sql_directory="${1}"
    local sql_script="${2}"

    printInfo "\nExecute SQL script ${sql_script} on source database"

    local output
    output=$(PGPASSWORD="${dbgn_db_source_password}" psql \
        -h "${dbgn_db_source_host}" -p "${dbgn_db_source_port}" \
        -U "${dbgn_db_source_user}" -d "${dbgn_db_source_name}" \
        -f "${sql_directory}/${sql_script}" 2>&1 | tee /dev/tty)

    analyseSqlExecutionOutput "${output}" "${sql_script}"
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
            jsonb_set(
                COALESCE(additional_data, '{}'::jsonb),
                '{migrate2026}',
                jsonb_build_object(
                    'idOrganismSrc', id_organisme
                )
            ) AS additional_data,
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
                jsonb_strip_nulls(
                    jsonb_build_object(
                        'idOrganismSrc', id_organisme,
                        'idRoleSrc', id_role
                    )
                )
            ) AS champs_addi,
            date_insert,
            date_update
        FROM utilisateurs.t_roles
        ORDER BY groupe DESC, id_role"

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

    exportCsvFromSrc "gn_synthese.t_sources" \
        "name_source, desc_source, entity_source_pk_field, url_source, meta_create_date, meta_update_date"
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
    # Don't print anything in this function, as its output is used in a condition to check if the DB exists or not
    local db_name="${1}"
    local exists=$(executeSuperAdminPsqlOnDst "-lqt" | grep -w "${db_name}" | wc -l)

    if [[ "${exists}" -gt 0 ]]; then
        printf '%s' "true"
    else
        printf '%s' "false"
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
    executeSuperAdminQueryOnDst "ALTER DATABASE ${dbgn_db_destination_name} OWNER TO ${dbgn_db_destination_user} ;"
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
    executeSuperAdminQueryOnDst "ALTER DATABASE ${backup_db_name} OWNER TO ${dbgn_db_destination_user} ;"
}

function initializeDestinationDb()  {
    printMsg "Initialize destination database..."

    executeSqlFile "020_initialize_destination_db.sql"
}

function restoreDefaultDataToDestinationDb() {
    printMsg "Restore default data to destination database..."

    executeQuery "INSERT INTO utilisateurs.bib_organismes (id_organisme, uuid_organisme, nom_organisme) VALUES
        ('2', 'e101b223-1354-4388-bdf9-cec5b189985e'::uuid, 'ALL (temp)');"
    executeQuery "SELECT reset_sequence('utilisateurs', 'bib_organismes', 'id_organisme', 'utilisateurs.bib_organismes_id_organisme_seq')"

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

    importSourceToDst
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

function importSourceToDst() {
    printInfo "Import CSV to table gn_synthese.t_sources"

    importCsvToDst "gn_synthese.t_sources" "name_source, desc_source, entity_source_pk_field, url_source, meta_create_date, meta_update_date"
    executeQuery "UPDATE gn_synthese.t_sources
        SET id_module = gn_commons.get_id_module_by_code('SYNTHESE')
        WHERE id_module IS NULL ;"
}

function cleanRefGeoInDestinationDb()  {
    printMsg "Clean ref geo data in destination database..."

    executeSqlFile "030_clean_ref_geo_data.sql"
}

function cleanUsersInDestinationDb()  {
    printMsg "Clean users data in destination database..."

    executeSqlFile "040_clean_users_data.sql"
}

function addPermissions() {
    printMsg "Add permissions in destination database..."

    executeSqlFile "050_add_permissions.sql"
}

function executeSqlScripts() {
    printMsg "Execute SQL scripts to update destination database..."

    executeSqlFile "060_replace_synthese_export_view.sql"
    executeSqlFile "070_replace_synthese_profile_view.sql"
    executeSqlFile "080_disable_status_text.sql"
    executeSqlFile "090_populate_bdc_statut_cor_text_area.sql"
    executeSqlFileWithInterpolatedVar "100_add_new_sensitivity_nomenclatures.sql"
    executeSqlFile "110_disable_permanently_sensitivity_triggers.sql"
    executeSqlFileWithInterpolatedVar "120_add_forest_flora_taxhub_attribut.sql"
    executeSqlFileWithInterpolatedVar "130_add_taxa_lists_taxhub_attribut.sql"
    executeSqlFile "140_update_sensitivity_area.sql"
    executeSqlFile "150_create_vm_for_synthese_export.sql"
    executeSqlFile "160_add_values_to_campanule_nomenclature.sql"
    executeSqlFile "170_updates_for_atlas_2.sql"
    executeSqlFileWithInterpolatedVar "180_add_invasive_species_taxhub_attribut.sql"
    executeSqlFile "185_add_values_to_ds_publique_nomenclature.sql"
}

function migratePermissionRequests() {
    printMsg "Migrate permission requests in destination database..."

    exportCsvFromSrcByQuery "pr_permission_request.tmp_permission_request" \
        "SELECT
            r."token",
            ur.uuid_role AS requested_by,
            r.processed_date,
            pr.uuid_role AS processed_by,
            r.end_date,
            r.geographic_filter,
            r.taxonomic_filter,
            r.additional_data,
            r.meta_create_date,
            r.meta_update_date
        FROM gn_permissions.t_requests AS r
            JOIN utilisateurs.t_roles AS ur
                ON r.id_role = ur.id_role
            JOIN utilisateurs.t_roles AS pr
                ON r.processed_by = pr.id_role
        WHERE r.end_date > now()
            AND r.sensitive_access = TRUE
            AND r.processed_state = 'accepted'"

    executeQuery "DROP TABLE IF EXISTS pr_permission_request.tmp_permission_request"
    executeQuery "CREATE TABLE pr_permission_request.tmp_permission_request (
            token UUID,
            requested_by UUID,
            processed_date TIMESTAMP,
            processed_by UUID,
            end_date DATE,
            geographic_filter text,
            taxonomic_filter text,
            additional_data JSONB,
            meta_create_date TIMESTAMP,
            meta_update_date TIMESTAMP,
            CONSTRAINT pk_tmp_permission_request PRIMARY KEY (token)
        );"
    importCsvToDst "pr_permission_request.tmp_permission_request"


    executeSqlFile "190_migrate_permission_requests.sql"

    executeQuery "DROP TABLE IF EXISTS pr_permission_request.tmp_permission_request"
}

function transfertExportModuleTables() {
    printMsg "Transfert export module tables from source to destination database..."

    local dump_file="${raw_dir}/module_exports_tables.dump"
    local tables_to_export=(
        "gn_exports.export_onf_contour"
        "gn_exports.export_onf_taxon"
    )

    local dump_args=()
    for table in "${tables_to_export[@]}"; do
        dump_args+=("-t" "$table")
    done

    if [[ ! -f "${dump_file}" ]]; then
        printVerbose "Dump Exports module tables to ${dump_file}"

        PGPASSWORD="${dbgn_db_source_password}" pg_dump \
            -h "${dbgn_db_source_host}" -p "${dbgn_db_source_port}" \
            -U "${dbgn_db_source_user}" -d "${dbgn_db_source_name}" -F c \
            "${dump_args[@]}" \
            -f "${dump_file}"

        if [ $? -ne 0 ]; then
            exitScript "❌ An error occurred during pg_dump (Export module)."
        fi
    else
        printVerbose "📍 Dump file ${dump_file} already exists. Skipping pg_dump for Export module."
    fi

    printVerbose "Restore Exports module tables to destination DB"
    PGPASSWORD="${dbgn_db_destination_password}" pg_restore \
        -h "${dbgn_db_destination_host}" -p "${dbgn_db_destination_port}" \
        -U "${dbgn_db_destination_user}" -d "${dbgn_db_destination_name}" \
        -1 "${dump_file}"

    if [ $? -eq 0 ]; then
        printInfo "✅ Migration of module Exports tables ended with success !"
    else
        exitScript "❌ An error occurred during pg_restore (Export module)."
    fi
}

function executeExportModuleScripts() {
    printMsg "Execute Exports module materialized views SQL script on destination database..."
    # Don't dump materialized view from Source DB beacause there is also some functions to restore

    local module_sql_dir="${root_dir}/modules/exports"
    local files=(
        "create_synthese_blurred.sql"
        "export_catalogue_taxons_region.sql"
        "export_cen_savoie_1.sql"
        "export_cen_savoie_2.sql"
        "export_cen_savoie_3.sql"
        "export_lo_parvi_1.sql"
        "export_lo_parvi_2.sql"
        "export_onf.sql"
        "export_pnr_chartreuse.sql"
        "export_pnr_haut_jura.sql"
        "export_pnr_livradois_forez_1.sql"
        "export_pnr_livradois_forez_2.sql"
        "export_pnr_massif_bauges.sql"
        "export_pnr_pilat.sql"
        "export_pnr_vercors_1.sql"
        "export_pnr_vercors_2.sql"
        "export_pnr_volcans_auvergne_1.sql"
        "export_pnr_volcans_auvergne_2.sql"
        "export_pnr_volcans_auvergne_3.sql"
        "export_pnr_volcans_auvergne_4.sql"
    )

    for file in "${files[@]}"; do
        executeSqlFile "${file}" "${module_sql_dir}"
    done
}

function transfertFlaviaGn2PgSchema() {
    printMsg "Transfert Flavia gn2pg schemas from source to destination database..."

    transfertSchema "gn2pg_flavia"
}

function cleanFlaviaGn2Pg() {
    printMsg "Clean Flavia Gn2Pg schemas in destination database..."

    executeSqlFile "200_clean_gn2pg_flavia_data.sql"
}

function insertFlaviaGn2PgDataToGN() {
    printMsg "Insert data from Flavia gn2pg schemas in destination database..."

    exexecuteSqlFileAsAdmin "210_insert_gn2pg_flavia_data.sql"
}

function transfertLpoGn2PgSchema() {
    printMsg "Transfert LPO gn2pg schemas from source to destination database..."

    transfertSchema "gn2pg_lpo"
}

function cleanLpoGn2Pg() {
    printMsg "Clean LPO Gn2Pg schemas in destination database..."

    executeSqlFile "220_clean_gn2pg_lpo_data.sql"
}

function insertLpoGn2PgDataToGN() {
    printMsg "Insert data from LPO gn2pg schemas in destination database..."

    executeSqlFile "230_insert_gn2pg_lpo_data.sql"
}

function transfertSchema() {
    local schema_name="${1}"
    printInfo "🚀 Starting transfert of ${schema_name} schema..."

    local transfert_time_start="$(date +%s)"
    executeQuery "DROP SCHEMA IF EXISTS ${schema_name} CASCADE ;"
    PGPASSWORD="${dbgn_db_source_password}" pg_dump -h "${dbgn_db_source_host}" -p "${dbgn_db_source_port}" \
        -U "${dbgn_db_source_user}" -d "${dbgn_db_source_name}" \
        -n "${schema_name}" -F c | \
    PGPASSWORD="${dbgn_db_destination_password}" pg_restore -h "${dbgn_db_destination_host}" -p "${dbgn_db_destination_port}" \
        -U "${dbgn_db_destination_user}" -d "${dbgn_db_destination_name}" \
        -1
    local result=${PIPESTATUS[1]}
    local transfert_time_end="$(date +%s)"
    local transfert_time_diff="$((${transfert_time_end} - ${transfert_time_start}))"

    printInfo "Total transfert time elapsed: $(displayTime "${transfert_time_diff}")"
    if [[ ${result} -eq 0 ]]; then
        printInfo "✅ Migration of ${schema_name} ended with success !"
    else
        exitScript "❌ An error occurred during the migration of ${schema_name}."
    fi
}

function insertCbnaDataToGN() {
    printMsg "Insert CBNA data to Synthese in destination database..."

    runImportUpdateScript "cbna" "2025-08-13"
}

function insertCbnmcDataToGN() {
    printMsg "Insert CBNMC data to Synthese in destination database..."

    runImportUpdateScript "cbnmc" "2025-07-28"
}

function runImportUpdateScript() {
    local org="${1}"
    local import_date="${2}"
    local filename_prefix="\${${org}_import_date}_sinp_aura_${org}_test"
    local script_root_dir="${root_dir}/${org}"
    local script_raw_dir="${script_root_dir}/data/raw"

    printVerbose "Delete previously extracted files in ${script_raw_dir}/data/raw :"
    cd "${script_raw_dir}/"
    rm -f ./*_rti.csv
    rm -f ./*.ini
    # Check if any .csv or .ini files exist. We expect none after the rm command.
    if [[ -z "$(find . -maxdepth 1 \( -name '*.csv' -o -name '*.ini' \) -print -quit)" ]]; then
        printVerbose "\t ${Gre}OK"
    else
        printVerbose "\t ${Red}KO"
    fi

    printVerbose "Check if ${org^^} settings.ini exists"
    cd "${script_root_dir}/config"
    if [[ -f "settings.ini" ]]; then
        printVerbose "\t copying settings.sample.ini to settings.ini."
        cp "settings.sample.ini" "settings.ini"
    else
        printVerbose "\t ignore copying the existing settings.ini file."
    fi

    printVerbose "Update import date and prefix in ${org^^} settings.ini file"
    cd "${script_root_dir}/config"
    sed -i \
        -e "s/^${org}_import_date=.*$/${org}_import_date=\"${import_date}\"/" \
        -e "s/^${org}_filename_prefix=.*$/${org}_filename_prefix=\"${filename_prefix}\"/" \
        "settings.ini"

    if grep -q "^db_name=" "settings.ini"; then
        sed -i -e "s/^db_name=.*$/db_name=\"${dbgn_db_destination_name}\"/" "settings.ini"
    else
        echo "db_name=\"${dbgn_db_destination_name}\"" >> "settings.ini"
    fi
    if grep -q "^db_user=" "settings.ini"; then
        sed -i -e "s/^db_user=.*$/db_user=\"${dbgn_db_destination_user}\"/" "settings.ini"
    else
        echo "db_user=\"${dbgn_db_destination_user}\"" >> "settings.ini"
    fi
    if grep -q "^db_pass=" "settings.ini"; then
        sed -i -e "s/^db_pass=.*$/db_pass=\"${dbgn_db_destination_password}\"/" "settings.ini"
    else
        echo "db_pass=\"${dbgn_db_destination_password}\"" >> "settings.ini"
    fi

    printVerbose "Run import script for ${org^^}"
    cd "${script_root_dir}/bin"
    ./import.sh --verbose
}

function reloadObservationsAreasLinks() {
    printMsg "Reload cor_area_synthese in destination database..."

    executeSqlFileOnSrcDb "${sql_shared_dir}" "reload_cor_area_synthese.sql"
}

function startMaintenanceTask() {
    printMsg "Start maintenance task in destination database..."
    local script_root_dir="${root_dir}/maintenance"

    cd "${script_root_dir}/bin"
    ./upkeep.sh --verbose
}

function executeSuperAdminQueryOnDst() {
    local sql_query="${1}"

    PGPASSWORD="${dbgn_db_destination_superadmin_password}" psql \
        -h "${dbgn_db_destination_host}" -p "${dbgn_db_destination_port}" \
        -U "${dbgn_db_destination_superadmin_name}" \
        -c "${sql_query}"
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

function executeQuery() {
    local query="${1}"

    printInfo "\nExecute SQL query on destination database"

    PGPASSWORD="${dbgn_db_destination_password}" psql \
        -h "${dbgn_db_destination_host}" -p "${dbgn_db_destination_port}" \
        -U "${dbgn_db_destination_user}" -d "${dbgn_db_destination_name}" \
        -c "${query}"
}

function executeSqlFile() {
    local sql_script="${1}"
    local sql_directory="${2:-${dbgn_sql_migrate_dir}}"

    printInfo "\nExecute SQL script ${sql_script} on destination database"

    local output
    output=$(PGPASSWORD="${dbgn_db_destination_password}" psql \
        -h "${dbgn_db_destination_host}" -p "${dbgn_db_destination_port}" \
        -U "${dbgn_db_destination_user}" -d "${dbgn_db_destination_name}" \
        -f "${sql_directory}/${sql_script}" 2>&1 | tee /dev/tty)

    analyseSqlExecutionOutput "${output}" "${sql_script}"
}

function exexecuteSqlFileAsAdmin() {
    local sql_script="${1}"
    local sql_directory="${2:-${dbgn_sql_migrate_dir}}"

    printInfo "\nExecute SQL script ${sql_script} as SUPERADMIN on destination database"

    local output
    output=$(PGPASSWORD="${dbgn_db_destination_superadmin_password}" psql \
        -h "${dbgn_db_destination_host}" -p "${dbgn_db_destination_port}" \
        -U "${dbgn_db_destination_superadmin_name}" -d "${dbgn_db_destination_name}" \
        -f "${sql_directory}/${sql_script}" 2>&1 | tee /dev/tty)

    analyseSqlExecutionOutput "${output}" "${sql_script}"
}

function executeSqlFileWithInterpolatedVar() {
    local sql_script="${1}"

    printInfo "\nExecute SQL script ${sql_script} with interpolated variables on destination database"

    local output
    output=$({
        cat "${dbgn_sql_migrate_dir}/${sql_script}" | \
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
