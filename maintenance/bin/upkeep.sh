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
    checkBinary ("jo" "jq" "ssh" "psql")

    #+----------------------------------------------------------------------------------------------------------+
    # Start script
    printInfo "${app_name} script started at: ${fmt_time_start}"

    update_script_running="$(pgrep -fl "gn2pg_cli|import_update.sh")"

    if [[ "${update_script_running}" == "" ]]; then
        checkNewData
        if [[ "${has_new_data}" == "true" ]]; then
            updateOutsideObservations
            updateInpnImages
            maintainDatabase
            refreshMaterializedViews
            rebuildGeoNatureAtlas
        else
            printError "No new data => stop upkeeping !"
        fi
    else
        printError "Updating data script running => stop upkeeping: ${update_script_running} !"
    fi

    #+----------------------------------------------------------------------------------------------------------+
    # Display script execution infos
    displayTimeElapsed
}

function checkNewData() {
    local readonly json="${raw_dir}/synthese_infos.json"
    has_new_data="false"

    local readonly count=$(export PGPASSWORD="${db_pass}"; \
        psql -h "${db_host}" -U "${db_user}" -d "${db_name}" \
            -AXqtc "SELECT COUNT(*) FROM gn_synthese.synthese;")

    local readonly max_id_synthese=$(export PGPASSWORD="${db_pass}"; \
        psql -h "${db_host}" -U "${db_user}" -d "${db_name}" \
            -AXqtc "SELECT MAX(id_synthese) FROM gn_synthese.synthese;")

    local readonly max_create_date=$(export PGPASSWORD="${db_pass}"; \
        psql -h "${db_host}" -U "${db_user}" -d "${db_name}" \
            -AXqtc "SELECT MAX(meta_create_date) FROM gn_synthese.synthese;")

    local readonly max_update_date=$(export PGPASSWORD="${db_pass}"; \
        psql -h "${db_host}" -U "${db_user}" -d "${db_name}" \
            -AXqtc "SELECT MAX(meta_update_date) FROM gn_synthese.synthese;")

    if [[ ! -f "${json}" ]]; then
        has_new_data="false"
    else
        last_count=$(jq .count "${json}")
        last_max_id_synthese=$(jq .maxIdSynthese "${json}")
        last_max_create_date=$(jq -r .maxCreateDate "${json}")
        last_max_update_date=$(jq -r .maxUpdateDate "${json}")
        last_create_at=$(jq -r .createdAt "${json}")

        if [[ "${count}" > "${last_count}" ]]; then
            has_new_data="true"
        fi
        if [[ "${max_id_synthese}" > "${last_max_id_synthese}" ]]; then
            has_new_data="true"
        fi
    fi

    jo -p \
        count=${db_count} maxIdSynthese=${max_id_synthese} maxCreateDate="${max_create_date}"  \
        maxUpdateDate="${max_update_date}" createdAt="$(date '+%Y-%m-%d %H:%M:%S')" \
        > "${json}"
}

function updateOutsideObservations() {
    printMsg "Create outside all tmp table..."
    export PGPASSWORD="${db_pass}"; \
        psql -h "${db_host}" -U "${db_user}" -d "${db_name}" \
            -f "${root_dir}/area-outside/data/sql/01_create_outside_all.sql"

    printMsg "Fix outside observations geometries..."
    export PGPASSWORD="${db_pass}"; \
        psql -h "${db_host}" -U "${db_user}" -d "${db_name}" \
            -f "${root_dir}/area-outside/data/sql/03_fix_outside_geom.sql"
}

function updateInpnImages() {
    printMsg "Update bib_noms table with new observations scientific names..."
    export PGPASSWORD="${db_pass}"; \
        psql -h "${db_host}" -U "${db_user}" -d "${db_name}" \
            -f "${sql_dir}/update_scinames_list.sql"

    printMsg "Run SINP update images on web-srv..."
    ssh geonat@web-aura-srv 'bash -s' < "${data_dir}/bash/update_sinp_images.sh"

    printMsg "Update first images in taxonomie.t_medias..."
    export PGPASSWORD="${db_pass}"; \
        psql -h "${db_host}" -U "${db_user}" -d "${db_name}" \
            -f "${sql_dir}/update_first_images.sql"
}

function maintainDatabase() {
    printMsg "Run database maintenance..."
    export PGPASSWORD="${db_pass}"; \
        psql -h "${db_host}" -U "${db_user}" -d "${db_name}" \
            -f "${sql_shared_dir}/synthese_maintenance.sql"
}

function refreshMaterializedViews() {
    printMsg "Run materialized view refreshes..."
    export PGPASSWORD="${db_pass}"; \
        psql -h "${db_host}" -U "${db_user}" -d "${db_name}" \
            -f "${sql_shared_dir}/refresh_materialized_view.sql"
}

function rebuildGeoNatureAtlas() {
    local atlas_path="/home/geonat/www/maintenance/atlas/"

    printMsg "Put the Atlas in maintenance..."
    ssh geonat@web-aura-srv "mv ${atlas_path}/maintenance.disable ${atlas_path}/maintenance.enable"

    printMsg "Put the Atlas in production..."
    ssh geonat@web-aura-srv 'bash -s' < "${data_dir}/bash/rebuild_atlas.sh"

    printMsg "Put the Atlas in production..."
    ssh geonat@web-aura-srv "mv ${atlas_path}/maintenance.enable ${atlas_path}/maintenance.disable"
}

main "${@}"
