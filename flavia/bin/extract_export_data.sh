#!/bin/bash
# Encoding : UTF-8
# Extract Export API data

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
    redirectOutput "${flavia_log_imports}"

    #+----------------------------------------------------------------------------------------------------------+
    # Start script
    printInfo "${app_name} script started at: ${fmt_time_start}"

    export PGPASSWORD="${db_pass}"; \
    psql -h "${db_host}" -U "${db_user}" -d "${db_name}" \
        -AXqtc "SELECT id_synthese FROM gn2pg_flavia.id_synthese_bloquant" \
        | while read -a id_synthese ; do
            printMsg "Importing ${id_synthese}"
            url="https://donnees.pole-invertebres.fr/api/exports/api/24?id_synthese=${id_synthese}"
            json=$(curl -X GET "${url}" -H "accept: application/json" --cookie "token=${flavia_auth_token}" | sed "s/'/''/g")

            export PGPASSWORD="${db_pass}"; \
            psql -h "${db_host}" -U "${db_user}" -d "${db_name}" \
                -c "UPDATE gn2pg_flavia.id_synthese_bloquant SET data_json = '${json}' WHERE id_synthese = ${id_synthese}"
        done

    #+----------------------------------------------------------------------------------------------------------+
    # Display script execution infos
    displayTimeElapsed
}

main "${@}"
