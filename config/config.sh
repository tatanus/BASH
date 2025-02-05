#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : config.sh
# DESCRIPTION : Configuration file for Bash scripts and pentesting environment.
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-08 19:57:22
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-08 19:57:22  | Adam Compton | Initial creation.
# =============================================================================

# Guard to prevent multiple sourcing
if [[ -z "${CONFIG_SH_LOADED:-}" ]]; then
    declare -g CONFIG_SH_LOADED=true

    # =============================================================================
    # GLOBAL SETTINGS
    # =============================================================================

    export DEBUG=false                  # Enable debug mode (true/false)
    export NO_DISPLAY=false             # Suppress display outputs (true/false)
    export _PASS=0                      # Success return code
    export _FAIL=1                      # Failure return code

    export PROXYCHAINS_CMD="proxychains4 -q " # Proxychains command
    export PROXYCHAINS_CONFIG="/etc/proxychains4.conf" # Proxychains config file

    export INTERACTIVE_MENU=false       # Enable interactive menus (true/false)

    # =============================================================================
    # BASH CONFIGURATION DIRECTORIES
    # =============================================================================

    export BASH_DIR="${HOME}/.config/bash"
    export BASH_LOG_DIR="${BASH_DIR}/log"

    # Ensure directories exist
    for dir in "${BASH_DIR}" "${BASH_LOG_DIR}"; do
        if [[ ! -d "${dir}" ]]; then
            mkdir -p "${dir}" || {
                echo "Failed to create directory: ${dir}" >&2
                exit "${_FAIL}"
            }
            printf "[* INFO  ] Created directory: %s\n" "${dir}"
        fi
    done

    # =============================================================================
    # SCRIPT FILES
    # =============================================================================

    export CONFIG_FILE="${SCRIPT_DIR}/config/config.sh"
    export MENU_FILE="${SCRIPT_DIR}/lib/menu.sh"
    export LOG_FILE="${SCRIPT_DIR}/setup.log"
    export MENU_TIMESTAMP_FILE="${SCRIPT_DIR}/menu_timestamps"

    # Ensure required files exist
    # shellcheck disable=SC2066
    for file in "${MENU_TIMESTAMP_FILE}"; do
        if [[ ! -f "${file}" ]]; then
            touch "${file}" || {
                echo "Failed to create file: ${file}" >&2
                exit "${_FAIL}"
            }
        fi
    done

    # =============================================================================
    # PENTEST CONFIGURATION
    # =============================================================================

    # Environment files
    export PENTEST_ENV_FILE="${BASH_DIR}/pentest.env.sh"
    export PENTEST_ALIAS_FILE="${BASH_DIR}/pentest.alias.sh"
    export PENTEST_KEYS_FILE="${BASH_DIR}/pentest.keys"
    export PENTEST_LOG_FILE="${BASH_DIR}/pentest.log"
    export PENTEST_MENU_TIMESTAMP_FILE="${BASH_DIR}/pentest_menu_timestamps"

    # Ensure pentest timestamp file exists
    if [[ ! -f "${PENTEST_MENU_TIMESTAMP_FILE}" ]]; then
        touch "${PENTEST_MENU_TIMESTAMP_FILE}" || {
            echo "Failed to create file: ${PENTEST_MENU_TIMESTAMP_FILE}" >&2
            exit "${_FAIL}"
        }
    fi

    # =============================================================================
    # DATA AND OUTPUT DIRECTORIES
    # =============================================================================

    export DATA_DIR="${HOME}/DATA"
    export TOOLS_DIR="${DATA_DIR}/TOOLS"
    export LOGS_DIR="${DATA_DIR}/LOGS"

    export ENGAGEMENT_DIR="${DATA_DIR}"
    export BACKUP_DIR="${ENGAGEMENT_DIR}/BACKUP"
    export RECON_DIR="${ENGAGEMENT_DIR}/RECON"
    export LOOT_DIR="${ENGAGEMENT_DIR}/LOOT"
    export CREDS_DIR="${LOOT_DIR}/CREDENTIALS"
    export OUTPUT_DIR="${ENGAGEMENT_DIR}/OUTPUT"
    export PORTSCAN_DIR="${OUTPUT_DIR}/PORTSCAN"
    export SHARES_DIR="${OUTPUT_DIR}/SHARES"
    export TEE_DIR="${OUTPUT_DIR}/TEE"

    # # Ensure directories exist
    # for dir in "${DATA_DIR}" "${TOOLS_DIR}" "${LOGS_DIR}" "${ENGAGEMENT_DIR}" "${BACKUP_DIR}" "${RECON_DIR}" "${LOOT_DIR}" "${CREDS_DIR}" "${OUTPUT_DIR}" "${PORTSCAN_DIR}" "${SHARES_DIR}"; do
    #     if [[ ! -d "${dir}" ]]; then
    #         mkdir -p "${dir}" || {
    #             echo "Failed to create directory: ${dir}" >&2
    #             exit "${_FAIL}"
    #         }
    #     fi
    # done

    # =============================================================================
    # INSTALLATION CONFIGURATION
    # =============================================================================

    export INSTALL_METASPLOIT=false     # Install Metasploit framework
    export INSTALL_NESSUS=false        # Install Nessus vulnerability scanner
    export SETUP_NESSUS=false          # Set up Nessus (true/false)
    export NESSUS_USER="pentest"       # Nessus default username
    export NESSUS_PASSWORD="123abc890XYZ" # Nessus default password
    export COMPILE_PYTHON=false        # Compile Python from source
    export INSTALL_PYTHON=true         # Install Python package

    export PYTHON_VERSION="3.12"       # Python version to install

    # =============================================================================
    # LOGGING CONFIGURATION
    # =============================================================================

    export BASH_LOG_FILE="${BASH_DIR}/bash_setup.log"

    # =============================================================================
    # END CONFIGURATION
    # =============================================================================
fi
