#!/bin/bash
# Encoding : UTF-8
# Update GeoNature with Gn2Pg

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
     -c | --config: name of config file to use with this script
     -n | --name: name of Gn2Pg source. Ex. : flavia, lpo.
     -t | --type: type of Gn2Pg download among: update, full. Default: update.
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
            "--name") set -- "${@}" "-n" ;;
            "--type") set -- "${@}" "-t" ;;
            "--"*) exitScript "ERROR : parameter '${arg}' invalid ! Use -h option to know more." 1 ;;
            *) set -- "${@}" "${arg}"
        esac
    done

    while getopts "hvxc:n:t:" option; do
        case "${option}" in
            "h") printScriptUsage ;;
            "v") readonly verbose=true ;;
            "x") readonly debug=true; set -x ;;
            "c") setting_file_path="${OPTARG}" ;;
            "n") gn2pg_source_name="${OPTARG}" ;;
            "t") gn2pg_update_type="${OPTARG}" ;;
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
    current_dir=$(dirname "${BASH_SOURCE[0]}")
    source "${current_dir}/../../shared/lib/utils.bash"

    #+----------------------------------------------------------------------------------------------------------+
    # Init script
    initScript "${@}"
    parseScriptOptions "${@}"
    loadScriptConfig "${setting_file_path-}"
    runChecks
    prepareParameters
    redirectOutput "${gn2pg_log_imports}"

    #+----------------------------------------------------------------------------------------------------------+
    # Start script
    printInfo "${app_name} update script started at: ${fmt_time_start}"

    # Prepare Gn2Pg update
    startStatusMessenger

    # Run Gn2Pg update
    printMsg "Running Gn2Pg updates with ${gn2pg_config_file_name} config..."
    cd "${current_dir}/../"
    pipenv run gn2pg_cli ${gn2pg_verbosity} ${gn2pg_update_type} "${gn2pg_config_file_name}"

    # Finalize Gn2Pg update
    stopStatusMessenger

    #+----------------------------------------------------------------------------------------------------------+
    # Display script execution infos
    displayTimeElapsed
}

function runChecks {
    if [[ -z "${gn2pg_source_name-}" ]]; then
        printError "Missing required parameter -n !"
        printScriptUsage
    fi
}

function prepareParameters() {
    gn2pg_verbosity=""
    if [[ ${verbose-} == true ]]; then
        gn2pg_verbosity="--verbose"
    fi

    if [[ "${gn2pg_update_type-}" == "update" ]]; then
        gn2pg_update_type="--update"
    elif [[ "${gn2pg_update_type-}" == "full" ]]; then
        gn2pg_update_type="--full"
    else
        gn2pg_update_type="--update"
    fi

    gn2pg_config_file_name="${gn2pg_source_name,,}_config.toml"
    sn="${gn2pg_source_name,,}"

    gn2pg_log_imports="${gn2pg_log_imports/\{source\}/${sn}}"
}

function startStatusMessenger() {
    last_download_date=$(export PGPASSWORD="${db_pass}"; \
        psql -h "${db_host}" -U "${db_user}" -d "${db_name}" \
            -AXqtc "SELECT last_ts \
            FROM gn2pg_${sn}.increment_log \
            WHERE source = '${sn}' AND controler = 'data' \
            ORDER BY last_ts DESC ;"
    )
    last_download_date=${last_download_date:-"1970-01-01 00:00:00"}
    display_type="${gn2pg_update_type//--/}"
    sendTelegram "🚀 ${app_name} started ${display_type^^} download for ${gn2pg_source_name^^} on ${HOSTNAME^^} …
        Last download date used: ${last_download_date}"
    runStatusMessenger &
    status_messenger_pid=$!
}

function runStatusMessenger() {
    while true; do
        extractDownloadedData
        sendTelegram "Data already downloaded: ${downloaded_data_count}
            ${errors_msg}
            Elapsed time: ${elapsed_time}"
        sleep ${gn2pg_messenger_pause}
    done
}

function extractDownloadedData() {
    downloaded_data_count=$(export PGPASSWORD="${db_pass}"; \
        psql -h "${db_host}" -U "${db_user}" -d "${db_name}" \
            -AXqtc "SELECT COUNT(id_data) \
            FROM gn2pg_${sn}.data_json \
            WHERE source = '${sn}' \
               AND controler = 'data' \
               AND type = 'synthese_with_metadata' \
               AND update_ts > '${last_download_date}' ;"
    )

    errors_count=$(export PGPASSWORD="${db_pass}"; \
        psql -h "${db_host}" -U "${db_user}" -d "${db_name}" \
            -AXqtc "SELECT COUNT(id_data) \
            FROM gn2pg_${sn}.error_log \
            WHERE source = '${sn}' \
               AND controler = 'data' \
               AND last_ts = '${last_download_date}' ;"
    )

    result="🟢"
    errors_msg=""
    if [[ "${errors_count}" != "0" ]]; then
        result="🔴"
        errors_msg="🔺 Errors: ${errors_count} 🔺"
    fi

    local time_end="$(date +%s)"
    local time_diff="$((${time_end} - ${time_start}))"
    elapsed_time="$(displayTime "${time_diff}")"
}

function stopStatusMessenger() {
    kill $status_messenger_pid >/dev/null 2>&1

    extractDownloadedData

    sendTelegram "${result} Gn2Pg download for ${gn2pg_source_name^^} completed in ${elapsed_time} !
        Downloaded data: ${downloaded_data_count}
        ${errors_msg}"
}

main "${@}"
