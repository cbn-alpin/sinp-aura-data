#!/bin/bash
# Encoding : UTF-8
# Import in GeoNature Database the CBNMC Flora Data

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

    while getopts "hvxc:" option; do
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
    redirectOutput "${cm_log_imports}"
    checkSuperuser

    #+----------------------------------------------------------------------------------------------------------+
    # Start script
    printInfo "${app_name} script started at: ${fmt_time_start}"

    downloadDataArchive
    extractArchive
    prepareDb
    insertSource
    insertOrganism
    # "user.csv" not used for now !
    #insertUser
    insertAcquisitionFramework
    insertDataset
    prepareSynthese
    insertSynthese
    maintainDb

    #+----------------------------------------------------------------------------------------------------------+
    # Display script execution infos
    displayTimeElapsed
}

function downloadDataArchive() {
    printMsg "Downloading ${app_code^^} data archive..."

    if [[ ! -f "${raw_dir}/${cm_filename_archive}" ]]; then
        downloadSftp "${sftp_user}" "${sftp_pwd}" \
            "${sftp_host}" "${sftp_port}" \
            "/${app_code}/${cm_filename_archive}" "${raw_dir}/${cm_filename_archive}"
     else
        printVerbose "Archive file \"${cm_filename_archive}\" already downloaded." ${Gra}
    fi
}

function extractArchive() {
    printMsg "Extracting import data CSV files..."

    if [[ -f "${raw_dir}/${cm_filename_archive}" ]]; then
        if [[ ! -f "${raw_dir}/${cm_filename_synthese}" ]]; then
            cd "${raw_dir}/"
            tar jxvf "${raw_dir}/${cm_filename_archive}"
        else
            printVerbose "CSV files already extracted." ${Gra}
        fi
    fi
}

function prepareDb() {
    printMsg "Inserting utils functions into GeoNature database..."
    export PGPASSWORD="${db_pass}"; \
        psql -h "${db_host}" -U "${db_user}" -d "${db_name}" \
            -f "${sql_shared_dir}/utils_functions.sql"

    printMsg "Inserting missing data into GeoNature database..."
    checkSuperuser
    sudo -n -u "${pg_admin_name}" -s \
        psql -d "${db_name}" \
            -f "${sql_dir}/initial/000_prepare_db.sql"
}


function insertSource() {
    local csv_to_import="${cm_filename_source%.csv}_rti.csv"

    printMsg "Parsing SOURCE CSV file..."
    if [[ ! -f "${raw_dir}/${csv_to_import}" ]]; then
        cd "${root_dir}/import-parser/"
        pipenv run python ./bin/gn_import_parser.py \
            --type "so" \
            --config "${conf_dir}/parser_actions_initial.ini" \
            "${raw_dir}/${cm_filename_source}"
    else
        printVerbose "SOURCE CSV file already parsed." ${Gra}
    fi

    printMsg "Inserting SOURCE data into GeoNature database..."
    checkSuperuser
    sudo -n -u "${pg_admin_name}" -s \
        psql -d "${db_name}" \
            -v gnDbOwner="${db_user}" \
            -v csvFilePath="${raw_dir}/${csv_to_import}" \
            -f "${sql_dir}/initial/001_copy_source.sql"
}

function insertOrganism() {
    local csv_to_import="${cm_filename_organism%.csv}_rti.csv"

    printMsg "Parsing ORGANISM CSV file..."
    if [[ ! -f "${raw_dir}/${csv_to_import}" ]]; then
        cd "${root_dir}/import-parser/"
        pipenv run python ./bin/gn_import_parser.py \
            --type "o" \
            --config "${conf_dir}/parser_actions_initial.ini" \
            "${raw_dir}/${cm_filename_organism}"
    else
        printVerbose "ORGANISM CSV file already parsed." ${Gra}
    fi

    printMsg "Inserting ORGANISM data into GeoNature database..."
    checkSuperuser
    sudo -n -u "${pg_admin_name}" -s \
        psql -d "${db_name}" \
            -v gnDbOwner="${db_user}" \
            -v csvFilePath="${raw_dir}/${csv_to_import}" \
            -f "${sql_dir}/initial/002_copy_organism.sql"
}

function insertUser() {
    local csv_to_import="${cm_filename_user%.csv}_rti.csv"

    printMsg "Parsing USER CSV file..."
    if [[ ! -f "${raw_dir}/${csv_to_import}" ]]; then
        cd "${root_dir}/import-parser/"
        pipenv run python ./bin/gn_import_parser.py \
            --type "u" \
            --config "${conf_dir}/parser_actions_initial.ini" \
            "${raw_dir}/${cm_filename_user}"
    else
        printVerbose "USER CSV file already parsed." ${Gra}
    fi

    printMsg "Inserting USER data into GeoNature database..."
    checkSuperuser
    sudo -n -u "${pg_admin_name}" -s \
        psql -d "${db_name}" \
            -v gnDbOwner="${db_user}" \
            -v csvFilePath="${raw_dir}/${csv_to_import}" \
            -f "${sql_dir}/initial/003_copy_user.sql"
}

function insertAcquisitionFramework() {
    local csv_to_import="${cm_filename_af%.csv}_rti.csv"

    printMsg "Parsing ACQUISITION FRAMEWORK CSV file..."
    if [[ ! -f "${raw_dir}/${csv_to_import}" ]]; then
        cd "${root_dir}/import-parser/"
        pipenv run python ./bin/gn_import_parser.py \
            --type "af" \
            --config "${conf_dir}/parser_actions_initial.ini" \
            "${raw_dir}/${cm_filename_af}"
    else
        printVerbose "ACQUISITION FRAMEWORK CSV file already parsed." ${Gra}
    fi

    printMsg "Inserting ACQUISITION FRAMEWORK data into GeoNature database..."
    checkSuperuser
    sudo -n -u "${pg_admin_name}" -s \
        psql -d "${db_name}" \
            -v gnDbOwner="${db_user}" \
            -v csvFilePath="${raw_dir}/${csv_to_import}" \
            -f "${sql_dir}/initial/004_copy_acquisition_framework.sql"
}

function insertDataset() {
    local csv_to_import="${cm_filename_dataset%.csv}_rti.csv"

    printMsg "Parsing DATASET CSV file..."
    if [[ ! -f "${raw_dir}/${csv_to_import}" ]]; then
        cd "${root_dir}/import-parser/"
        pipenv run python ./bin/gn_import_parser.py \
            --type "d" \
            --config "${conf_dir}/parser_actions_initial.ini" \
            "${raw_dir}/${cm_filename_dataset}"
    else
        printVerbose "DATASET CSV file already parsed." ${Gra}
    fi

    printMsg "Inserting DATASET data into GeoNature database..."
    checkSuperuser
    sudo -n -u "${pg_admin_name}" -s \
        psql -d "${db_name}" \
            -v gnDbOwner="${db_user}" \
            -v csvFilePath="${raw_dir}/${csv_to_import}" \
            -f "${sql_dir}/initial/005_copy_dataset.sql"
}

function prepareSynthese() {
    printMsg "Preparing GeoNature database before deleting data into synthese table ..."
    export PGPASSWORD="${db_pass}"; \
        psql -h "${db_host}" -U "${db_user}" -d "${db_name}" \
            -f "${sql_shared_dir}/synthese_before_delete.sql"

    printMsg "Deleting previously loaded synthese data with this sources..."
    export PGPASSWORD="${db_pass}"; \
        psql -h "${db_host}" -U "${db_user}" -d "${db_name}" \
            -f "${sql_dir}/initial/006_prepare_synthese.sql"

    printMsg "Restoring GeoNature database after deleting data into syntese table ..."
    export PGPASSWORD="${db_pass}"; \
        psql -h "${db_host}" -U "${db_user}" -d "${db_name}" \
            -f "${sql_shared_dir}/synthese_after_delete.sql"
}

function insertSynthese() {
    local csv_to_import="${cm_filename_synthese%.csv}_rti.csv"

    printMsg "Parsing SYNTHESE CSV file..."
    if [[ ! -f "${raw_dir}/${csv_to_import}" ]]; then
        cd "${root_dir}/import-parser/"
        pipenv run python ./bin/gn_import_parser.py \
            --type "s" \
            --config "${conf_dir}/parser_actions_initial.ini" \
            "${raw_dir}/${cm_filename_synthese}"
    else
        printVerbose "SYNTHESE CSV file already parsed." ${Gra}
    fi

    printMsg "Preparing GeoNature database before inserting data into synthese table ..."
    checkSuperuser
    sudo -n -u "${pg_admin_name}" -s \
        psql -d "${db_name}" \
            -f "${sql_shared_dir}/synthese_before_insert.sql"

    printMsg "Inserting synthese data into GeoNature database..."
    checkSuperuser
    sudo -n -u "${pg_admin_name}" -s \
        psql -d "${db_name}" \
            -v csvFilePath="${raw_dir}/${csv_to_import}" \
            -f "${sql_dir}/initial/007_copy_synthese.sql"

    printMsg "Restoring GeoNature database after inserting data into synthese table ..."
    checkSuperuser
    sudo -n -u "${pg_admin_name}" -s \
        psql -d "${db_name}" \
            -f "${sql_shared_dir}/synthese_after_insert.sql"
}

function maintainDb() {
    printMsg "Executing database maintenance on updated tables..."

    checkSuperuser
    sudo -n -u "${pg_admin_name}" -s \
        psql -d "${db_name}" \
            -f "${sql_shared_dir}/synthese_maintenance.sql"
}

main "${@}"
