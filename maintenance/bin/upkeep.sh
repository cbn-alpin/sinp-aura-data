#!/bin/bash
# Encoding : UTF-8
# Job to do after imported new data in GeoNature database.

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
     -c | --config: name of config file to use
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
    current_dir=$(dirname "${BASH_SOURCE[0]}")
    source "${current_dir}/../../shared/lib/utils.bash"

    #+----------------------------------------------------------------------------------------------------------+
    # Init script
    initScript "${@}"
    parseScriptOptions "${@}"
    loadScriptConfig "${setting_file_path-}"
    redirectOutput "${gnuk_log_imports}"
    runChecks

    #+----------------------------------------------------------------------------------------------------------+
    # Start script
    printInfo "${app_name} script started at: ${fmt_time_start}"

    printMsg "Check update script running..."
    update_script_running="$(pgrep -fl 'gn2pg_cli|import_update.sh' || echo 'NO')"

    if [[ "${update_script_running}" == "NO" ]]; then
        printInfo "No update script running => continue..."

        checkNewData
        sendStartMessage
        if [[ "${has_new_data}" == "true" ]]; then
            updateOutsideObservations
            updateInpnImages
            refreshGeoNatureCore
            refreshGeoNatureExport
            refreshBiodivTerritory
            refreshAtlas
        else
            printError "No new data => stop upkeeping !"
        fi
        sendStopMessage
    else
        printError "Updating data script running => stop upkeeping: ${update_script_running} !"
        sendDelayedMessage
    fi

    #+----------------------------------------------------------------------------------------------------------+
    # Display script execution infos
    displayTimeElapsed
}

function runChecks {
    local readonly commands=("jo" "jq" "ssh" "psql")
    checkBinary "${commands[@]}"
}

function checkNewData() {
    printMsg "Check new data..."

    extractDbNewInfos
    readJsonLastInfos
    evaluateNewDataReason

    if [[ "${has_new_data}" == "true" ]]; then
        printInfo "New data reason: ${reason}"
    fi

    writeNewJsonContent
}

function extractDbNewInfos() {
    count_id_synthese=$(export PGPASSWORD="${db_pass}"; \
        psql -h "${db_host}" -U "${db_user}" -d "${db_name}" \
            -AXqtc "SELECT COUNT(*) FROM gn_synthese.synthese;")

    max_id_synthese=$(export PGPASSWORD="${db_pass}"; \
        psql -h "${db_host}" -U "${db_user}" -d "${db_name}" \
            -AXqtc "SELECT MAX(id_synthese) FROM gn_synthese.synthese;")

    max_create_date=$(export PGPASSWORD="${db_pass}"; \
        psql -h "${db_host}" -U "${db_user}" -d "${db_name}" \
            -AXqtc "SELECT MAX(meta_create_date) FROM gn_synthese.synthese;")

    max_update_date=$(export PGPASSWORD="${db_pass}"; \
        psql -h "${db_host}" -U "${db_user}" -d "${db_name}" \
            -AXqtc "SELECT MAX(meta_update_date) FROM gn_synthese.synthese;")
}

function readJsonLastInfos() {
    if [[ -f "${gnuk_json}" ]]; then
        last_count_id_synthese=$(jq .count "${gnuk_json}")
        last_max_id_synthese=$(jq .maxIdSynthese "${gnuk_json}")
        last_max_create_date=$(jq -r .maxCreateDate "${gnuk_json}")
        last_max_update_date=$(jq -r .maxUpdateDate "${gnuk_json}")
        last_create_at=$(jq -r .createdAt "${gnuk_json}")
    fi
}

function evaluateNewDataReason() {
    has_new_data="false"
    reason=""
    if [[ ! -f "${gnuk_json}" ]]; then
        has_new_data="true"
        reason="No JSON file"
    else
        if [[ "${count_id_synthese}" != "${last_count_id_synthese}" ]]; then
            has_new_data="true"
            reason="observations count ${count_id_synthese} != last observations count ${last_count_id_synthese}"
        fi
        if [[ "${max_id_synthese}" > "${last_max_id_synthese}" ]]; then
            has_new_data="true"
            reason="max id synthese ${max_id_synthese} > last max id synthese ${last_max_id_synthese}"
        fi
        if [[ "${max_update_date}" > "${last_max_update_date}" ]]; then
            has_new_data="true"
            reason="max update date ${max_update_date} > last update date ${last_max_update_date}"
        fi
    fi
}

function writeNewJsonContent() {
    jo -p \
        count=${count_id_synthese} maxIdSynthese=${max_id_synthese} maxCreateDate="${max_create_date}"  \
        maxUpdateDate="${max_update_date}" createdAt="$(date '+%Y-%m-%d %H:%M:%S')" \
        > "${gnuk_json}"
}

function sendStartMessage() {
    buildNewDataDetails
    sendTelegram "🚀 ${app_name} started on ${HOSTNAME^^} …
        Update script running: ${update_script_running}
        Has new data: ${has_new_data}
        Reason: ${reason}
        ${new_data_details-}"
}

function buildNewDataDetails() {
    new_data_details=""
    if [[ "${has_new_data}" == "true" ]]; then
        new_data_details="
            ---------------------------
            Type           : New / Last
            obs count      : ${count_id_synthese-} / ${last_count_id_synthese-}
            max id synthese: ${max_id_synthese-} / ${last_max_id_synthese-}
            max create date: ${max_create_date-} / ${last_max_create_date-}
            max update date: ${max_update_date-} / ${last_max_update_date-}
            "
    fi
}

function updateOutsideObservations() {
    msg="Creating outside all tmp table..."
    export PGPASSWORD="${db_pass}"; \
        psql -h "${db_host}" -U "${db_user}" -d "${db_name}" \
            -v ON_ERROR_STOP=1 \
            -f "${root_dir}/area-outside/data/sql/01_create_outside_all.sql"
    alert $? "${msg}"

    msg="Fixing outside observations geometries..."
    export PGPASSWORD="${db_pass}"; \
        psql -h "${db_host}" -U "${db_user}" -d "${db_name}" \
            -v ON_ERROR_STOP=1 \
            -f "${root_dir}/area-outside/data/sql/03_fix_outside_geom.sql"
    alert $? "${msg}"
}

function updateInpnImages() {
    msg="Updating bib_noms table with new observations scientific names..."
    export PGPASSWORD="${db_pass}"; \
        psql -h "${db_host}" -U "${db_user}" -d "${db_name}" \
            -v ON_ERROR_STOP=1 \
            -f "${sql_dir}/update_scinames_list.sql"
    alert $? "${msg}"

    local readonly inpn_media_script_dir="${gnuk_inpn_media_script_dir}"
    if  [[ "${gnuk_local_inpn_import_media_script}" = true ]] && \
        [[ -f "${inpn_media_script_dir}/import_inpn_media.py" ]]; then
        notify "Run SINP update images on ${HOSTNAME}..."
        cd "${inpn_media_script_dir}/"
        source venv/bin/activate
        python import_inpn_media.py
        deactivate;
        cd "${bin_dir}"
    else
        notify "Copy update_sinp_image.sh script on web-srv..."
        scp "${data_dir}/bash/update_sinp_images.sh" geonat@web-aura-sinp:~/dwl/

        ssh -q geonat@web-aura-sinp [[ -f ${inpn_media_script_dir}/config.py ]] && \
            printVerbose "INPN Img config file exists." || \
            printError "🔴 INPN Img config file does not exist!";

        ssh -q geonat@web-aura-sinp [[ -d ${inpn_media_script_dir}/venv ]] && \
            printVerbose "INPN Img venv dir exists." || \
            printError "🔴 INPN Img venv dir does not exist!";

        notify "Run SINP update images on web-srv..."
        ssh geonat@web-aura-sinp ~/dwl/update_sinp_images.sh

        # Wait until updating images on wb-srv finish
        sleep 5
        waiting="alive"
        while [[ "alive" == "${waiting}" ]]; do
            waiting="stop"
            if ssh geonat@web-aura-sinp "pgrep -fa 'import_inpn_media.py'"; then
                notify "Process 'import_inpn_media.py' is running at $(date '+%H:%M:%S') on web-srv... "
                waiting="alive"
                sleep 120
                continue
            else
                notify "Process 'import_inpn_media.py' is finish at $(date '+%H:%M:%S') on web-srv !"
                updateFirstImages
            fi
        done
    fi
}

function updateFirstImages() {
    msg="Updating first images in taxonomie.t_medias..."
    notify "${msg}"
    export PGPASSWORD="${db_pass}"; \
        psql -h "${db_host}" -U "${db_user}" -d "${db_name}" \
            -v ON_ERROR_STOP=1 \
            -f "${sql_dir}/update_first_images.sql"
    alert $? "${msg}"
}

function refreshGeoNatureCore() {
    msg="Refreshing GeoNature core materialized views on db-srv..."
    notify "${msg}"
    export PGPASSWORD="${db_pass}"; \
        psql -h "${db_host}" -U "${db_user}" -d "${db_name}" \
            -v ON_ERROR_STOP=1 \
            -f "${sql_shared_dir}/refresh_materialized_view.sql"
    alert $? "${msg}"
}

function refreshGeoNatureExport() {
    msg="Refreshing GeoNature Export materialized views on db-srv..."
    notify "${msg}"
    export PGPASSWORD="${db_pass}"; \
        psql -h "${db_host}" -U "${db_user}" -d "${db_name}" \
            -v ON_ERROR_STOP=1 \
            -f "${sql_dir}/geonature_refresh.sql"
    alert $? "${msg}"
}

function refreshBiodivTerritory() {
    msg="Refreshing Biodiv'territory materialized views on db-srv..."
    notify "${msg}"
    export PGPASSWORD="${db_pass}"; \
        psql -h "${db_host}" -U "${db_user}" -d "${db_name}" \
            -v ON_ERROR_STOP=1 \
            -f "${root_dir}/biodivterritory/data/sql/update/refresh_materialized_views.sql"
    alert $? "${msg}"
}

function refreshAtlas() {
    msg="Refreshing Atlas materialized views on db-srv..."
    notify "${msg}"
    export PGPASSWORD="${db_pass}"; \
        psql -h "${db_host}" -U "${db_user}" -d "${db_atlas_name}" \
            -v ON_ERROR_STOP=1 \
            -f "${sql_dir}/atlas_refresh.sql"
    alert $? "${msg}"
}

function notify() {
    if [[ $# -lt 1 ]]; then
        exitScript "Missing required argument to ${FUNCNAME[0]}()!" 2
    fi
    local message="${1}"
    printMsg "${message}"
    computeElapsedTime
    sendTelegram "🔵 ${message}
        Elapsed time: ${elapsed_time}"
}

function alert() {
    if [[ $# -lt 2 ]]; then
        exitScript "Missing required argument to ${FUNCNAME[0]}()!" 2
    fi
    local status="${1}"
    local action="${2,}"

    local message=""
    if [[ "${status}" == "0" ]]; then
        message="🟢 SUCCESS of ${action}"
    elif [[ "${status}" == "1" ]]; then
        message="🔴 FATAL ERROR occurred while ${action}"
    elif [[ "${status}" == "2" ]]; then
        message="🔴 BAD CONNECTION to server occurred while ${action}"
    elif [[ "${status}" == "3" ]]; then
        message="🔴 ERROR IN SCRIPT occurred while ${action}"
    fi

    printMsg "${message}"
    sendTelegram "${message}
        Time: $(date)"
}

function sendStopMessage() {
    computeElapsedTime
    sendTelegram "🟢 ${app_name} finished on ${HOSTNAME^^} …
        Elapsed time: ${elapsed_time}"
}

function sendDelayedMessage() {
    computeElapsedTime
    sendTelegram "🟠 ${app_name} stop upkeeping on ${HOSTNAME^^} …
        Update script running: ${update_script_running} !
        Elapsed time: ${elapsed_time}"
}

function computeElapsedTime() {
    local time_end="$(date +%s)"
    local time_diff="$((${time_end} - ${time_start}))"
    elapsed_time="$(displayTime "${time_diff}")"
}

main "${@}"
