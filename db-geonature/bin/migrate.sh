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

    initializeDestinationDb
    exportCsvFilesFromSourceDb
    importCsvFilesToDestinationDb
    executeSqlScripts

    #+----------------------------------------------------------------------------------------------------------+
    # Display script execution infos
    displayTimeElapsed
}

function initializeDestinationDb()  {
    printMsg "Initialize destination database..."

    PGPASSWORD="${dbgn_db_destination_password}" psql \
        -h "${dbgn_db_destination_host}" -p "${dbgn_db_destination_port}" \
        -U "${dbgn_db_destination_user}" -d "${dbgn_db_destination_name}" \
        -f "${sql_dir}/000_initialize_destination_db.sql"
}

function exportCsvFilesFromSourceDb() {
    printMsg "Export to CSV files data from source database..."

    exportCsvFromSrc "ref_geo.bib_areas_types"
    exportCsvFromSrc "ref_geo.l_areas"
    exportCsvFromSrc "ref_geo.li_grids"
    exportCsvFromSrc "ref_geo.li_municipalities"
}

function exportCsvFromSrc() {
    local schema_table="${1}"
    local table="${schema_table#*.}"
    local output="${raw_dir}/${table}.csv"

    printInfo "Export CSV for table ${schema_table}"

    PGPASSWORD="${dbgn_db_source_password}" psql \
        -h "${dbgn_db_source_host}" -p "${dbgn_db_source_port}" \
        -U "${dbgn_db_source_user}" -d "${dbgn_db_source_name}" \
        -c "\COPY ${schema_table} TO STDOUT WITH CSV HEADER" > "${output}"
    printVerbose "${output} file created"
}

function importCsvFilesToDestinationDb() {
    printMsg "Import to destination database the CSV files..."

    importCsvToDst "ref_geo.bib_areas_types"
    importCsvToDst "ref_geo.l_areas"
    importCsvToDst "ref_geo.li_grids"
    importCsvToDst "ref_geo.li_municipalities"
}

function importCsvToDst() {
    local schema_table="${1}"
    local table="${schema_table#*.}"
    local input="${raw_dir}/${table}.csv"

    printInfo "Import CSV to table ${schema_table}"

    PGPASSWORD="${dbgn_db_destination_password}" psql \
        -h "${dbgn_db_destination_host}" -p "${dbgn_db_destination_port}" \
        -U "${dbgn_db_destination_user}" -d "${dbgn_db_destination_name}" \
        -c "\COPY ${schema_table} FROM STDIN WITH CSV HEADER" < "${input}"
    printVerbose "Data loaded into ${schema_table} from ${input} file."
}

function executeSqlScripts() {
    printMsg "Execute SQL scripts to update destination database..."

    # TODO: update SQL code for this SQL scripts
    executeSqlFile "001_replace_synthese_export_view.sql"
    executeSqlFile "002_replace_synthese_profile_view.sql"
    executeSqlFile "003_disable_status_text.sql"
    executeSqlFile "004_populate_bdc_statut_cor_text_area.sql"
    executeSqlFile "005_add_new_sensitivity_nomenclatures.sql"
    executeSqlFile "006_disable_permanently_sensitivity_triggers.sql"
    executeSqlFile "007_add_forest_flora_taxhub_attribut.sql"
    executeSqlFile "008_add_taxa_lists_taxhub_attribut.sql"
    executeSqlFile "009_update_sensitivity_area.sql"
    executeSqlFile "010_create_vm_for_synthese_export.sql"
    executeSqlFile "011_add_values_to_campanule_nomenclature.sql"
    executeSqlFile "012_updates_for_atlas_2.sql"
    executeSqlFile "013_add_invasive_species_taxhub_attribut.sql"
}

function executeSqlFile() {
    local sql_script="${1}"

    printInfo "Execute SQL script ${sql_script} on destination database"

    PGPASSWORD="${dbgn_db_destination_password}" psql \
        -h "${dbgn_db_destination_host}" -p "${dbgn_db_destination_port}" \
        -U "${dbgn_db_destination_user}" -d "${dbgn_db_destination_name}" \
        -f "${sql_dir}/${sql_script}"
}

main "${@}"
