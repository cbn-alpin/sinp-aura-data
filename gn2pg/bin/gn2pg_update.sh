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

    # Run Gn2Pg update
    startGn2Pg

    # Wait for the initial import log entry to be created and get its ID
    waitForInitialImportLog

    # Start status messenger in background
    startStatusMessenger

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

function startGn2Pg() {
    printMsg "Starting ${app_name} updates in background with ${gn2pg_config_file_name} config..."
    cd "${current_dir}/../"
    pipenv run gn2pg_cli ${gn2pg_verbosity} download ${gn2pg_update_type} "${gn2pg_config_file_name}" &
    gn2pg_pid=$! # Store PID of background process

    sendTelegram "🚀 GN2PG CLI started in background with pid ${gn2pg_pid} for ${gn2pg_source_name^^}"
}

# DESC: Wait for Gn2Pg to create the initial import log entry and set last_import_id
# ARGS: None
# OUTS: Sets global last_import_id
function waitForInitialImportLog() {
    printMsg "Waiting for ${app_name} to create initial import log entry..."
    local attempts=0
    local max_attempts=60 # Wait up to 60 seconds (e.g., 1 second per attempt)
    last_import_id="0" # Initialize to ensure loop runs
    while [[ "${last_import_id}" == "0" || -z "${last_import_id}" ]]; do
        extractLastImportId # This function sets the global last_import_id
        if [[ "${last_import_id}" != "0" && -n "${last_import_id}" ]]; then
            printMsg "Initial import log entry found: ID ${last_import_id}"
            break
        fi
        attempts=$((attempts + 1))
        if [[ "${attempts}" -ge "${max_attempts}" ]]; then
            printError "Timeout waiting for initial ${app_name} import log entry."
            sendTelegram "❌ ${app_name} failed to start ${gn2pg_update_type//--/^^} download
                for ${gn2pg_source_name^^} on ${HOSTNAME^^}
                (Import ID not found after waiting)!"
            exitScript "Failed to start Gn2Pg download." 1
        fi
        sleep 1
    done
}

function startStatusMessenger() {
    display_type="${gn2pg_update_type//--/}"
    sendTelegram "🚀 ${app_name} started ${display_type^^} download for ${gn2pg_source_name^^} on ${HOSTNAME^^} (Import ID: ${last_import_id})…"
    runStatusMessenger & # This is where it goes into background
    status_messenger_pid=$!
}

function runStatusMessenger() {
    while true; do
        extractDownloadedData
        sendTelegram "${gn2pg_source_name^^} - Data already downloaded: ${api_count_items}
            Elapsed time: ${elapsed_time}
            ${errors_msg}"
        sleep ${gn2pg_messenger_pause}
    done
}

function extractLastImportId() {
    local extract_import_id=$(export PGPASSWORD="${db_pass}"; \
        psql -h "${db_host}" -U "${db_user}" -d "${db_name}" \
            -AXqtc "SELECT id \
            FROM gn2pg_${sn}.import_log \
            WHERE source = '${sn}' \
                AND controler = 'data' \
                AND xfer_status IN ('init', 'importing data') \
            ORDER BY xfer_start_ts DESC \
            LIMIT 1 ;"
    )
    last_import_id=${extract_import_id:-"0"}
    if [[ "${last_import_id}" != "0" ]]; then
        sendTelegram "🆔 ${gn2pg_source_name^^} new import ID: ${last_import_id}"
    fi

}

function extractDownloadedData() {
    local import_data=$(export PGPASSWORD="${db_pass}"; \
        psql -h "${db_host}" -U "${db_user}" -d "${db_name}" \
            -F '|' -AXqtc "SELECT \
                api_count_items,
                api_count_errors,
                data_count_upserts,
                data_count_delete,
                data_count_errors,
                metadata_count_upserts,
                metadata_count_errors \
            FROM gn2pg_${sn}.import_log \
            WHERE source = '${sn}' \
               AND controler = 'data' \
               AND id = '${last_import_id}' ;"
    )

    # Parse the pipe-delimited output into variables
    IFS='|' read -r api_count_items \
        api_count_errors \
        data_count_upserts \
        data_count_delete \
        data_count_errors \
        metadata_count_upserts \
        metadata_count_errors <<< "${import_data}"

    errors_msg=""
    if [[ "${api_count_errors}" != "0" ]]; then
            errors_msg+="🔺 API Errors: ${api_count_errors:-"-"}"
    fi
    if [[ "${data_count_errors}" != "0" ]]; then
            errors_msg+="🔺 Data Errors: ${data_count_errors:-"-"}"
    fi
    if [[ "${metadata_count_errors}" != "0" ]]; then
            errors_msg+="🔺 Metadata Errors: ${metadata_count_errors:-"-"}"
    fi

    result_msg="Data upserts: ${data_count_upserts:-"-"}, "
    result_msg+="deletes: ${data_count_delete:-"-"}, "
    result_msg+="metadata upserts: ${metadata_count_upserts:-"-"}."

    result_icon="🟢"
    if [[ ! -z "${errors_msg}" ]]; then
        result_icon="🔴"
    fi

    local time_end="$(date +%s)"
    local time_diff="$((${time_end} - ${time_start}))"
    elapsed_time="$(displayTime "${time_diff}")"
}

function stopStatusMessenger() {
    kill $status_messenger_pid >/dev/null 2>&1
    extractDownloadInfos
    extractDownloadedData

    sendTelegram "${result_icon} Gn2Pg download for ${gn2pg_source_name^^} completed in ${elapsed_time} !
        ${result_msg}
        ${errors_msg}"
}

function extractDownloadInfos() {
    local import_data=$(export PGPASSWORD="${db_pass}"; \
        psql -h "${db_host}" -U "${db_user}" -d "${db_name}" \
            -F '|' -AXqtc "SELECT \
                xfer_type, \
                xfer_status, \
                xfer_start_ts, \
                xfer_end_ts, \
                xfer_filters, \
                comment \
            FROM gn2pg_${sn}.import_log \
            WHERE source = '${sn}' \
               AND controler = 'data' \
               AND id = '${last_import_id}' ;"
    )

    # Parse the pipe-delimited output into variables
    IFS='|' read -r api_count_items \
        xfer_type \
        xfer_status \
        xfer_start_ts \
        xfer_end_ts \
        xfer_filters \
        xfer_comment <<< "${import_data}"

    sendTelegram "📰 ${gn2pg_source_name^^} import ${last_import_id} infos:
        Type: ${xfer_type}
        Status: ${xfer_status}
        Start at: ${xfer_start_ts}
        End at: ${xfer_end_ts}
        Filters: ${xfer_filters}
        Comment: ${xfer_comment}"
}

main "${@}"
