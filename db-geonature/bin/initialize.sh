#!/bin/bash
# Encoding : UTF-8
# Execute DB GeoNature SQL files


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
    checkSuperuser

    # Check commands exist on system
    local readonly commands=("sshpass" "sftp" "psql")
    checkBinary "${commands[@]}"

    #+----------------------------------------------------------------------------------------------------------+
    # Start script
    printInfo "${app_name} import script started at: ${fmt_time_start}"

    downloadGeoRef
    updateGeoRef
    executeSql

    #+----------------------------------------------------------------------------------------------------------+
    # Display script execution infos
    displayTimeElapsed
}

function downloadGeoRef() {
    printMsg "Downloading geo ref data..."
    if ! [[ -f "${dbgn_geo_ref_archive_path_local}" ]]; then
        downloadSftp "${sftp_user}" "${sftp_pwd}" \
            "${sftp_host}" "${sftp_port}" \
            "${dbgn_geo_ref_archive_path_dist}" "${dbgn_geo_ref_archive_path_local}"
    else
        printVerbose "Archive of geo ref was already downloaded !"
    fi

    printMsg "Uncompressing archive file..."
    if ! [[ -f "${dbgn_geo_ref_sql_path_local}" ]]; then    
        cd ${raw_dir}/
        tar -xf ${dbgn_geo_ref_archive_path_local}
        chmod 644 "${dbgn_geo_ref_sql_path_local}"
    else
        printVerbose "Archive of geo ref was already uncompressed !"
    fi
}

function updateGeoRef() {
    printMsg "Replace standard geo ref..."
    checkSuperuser
    sudo -n -u "${pg_admin_name}" -s \
        psql -d "${db_name}" \
            -f "${dbgn_geo_ref_sql_path_local}"
}

function executeSql() {
    printMsg "Updating modules..."
    export PGPASSWORD="${db_pass}"; \
        psql -h "${db_host}" -U "${db_user}" -d "${db_name}" \
            -f "${sql_dir}/01_update_modules.sql"

    printMsg "Replace Synthese export view..."
    export PGPASSWORD="${db_pass}"; \
        psql -h "${db_host}" -U "${db_user}" -d "${db_name}" \
            -f "${sql_dir}/02_replace_synthese_export_view.sql"

    printMsg "Fixing GN database with superuser rights..."
    checkSuperuser
    sudo -n -u "${pg_admin_name}" -s \
        psql -d "${db_name}" \
            -f "${sql_dir}/03_fix_as_superuser.sql"

    printMsg "Fixing GN database with owner rights..."
    export PGPASSWORD="${db_pass}"; \
        psql -h "${db_host}" -U "${db_user}" -d "${db_name}" \
            -f "${sql_dir}/04_fix_as_user.sql"
    
    printMsg "Adding SINP area type and geom..."
    export PGPASSWORD="${db_pass}"; \
        psql -h "${db_host}" -U "${db_user}" -d "${db_name}" \
            -v sinpRegCode="${dbgb_sinp_reg_code}" \
            -f "${sql_dir}/05_add_sinp_area.sql"
}

main "${@}"
