#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : config.sh
# DESCRIPTION :
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

    # Debug mode (set to true or false)
    export DEBUG=false
    export NO_DISPLAY=false

    # pass/fail/true/fall variables
    export _PASS=0
    export _FAIL=1

    # Enable proxychains4 for certain commands (true/false)
    export PROXYCHAINS_CMD="proxychains4 -q "

    # Proxychains4 configuration file
    export PROXYCHAINS_CONFIG="/etc/proxychains4.conf"

    # Interactive menu
    export INTERACTIVE_MENU=false

    # BASH Directory
    export BASH_DIR="${HOME}/.config/bash"
    export BASH_LOG_DIR="${BASH_DIR}/log"

    # Ensure the BASH directory exists
    if [[ ! -d "${BASH_DIR}" ]]; then
        mkdir -p "${BASH_DIR}" || {
            echo "Failed to create directory: ${BASH_DIR}"
            exit 1
        }
        info "Created directory: ${BASH_DIR}"
    fi

    # Ensure the BASH directory exists
    if [[ ! -d "${BASH_LOG_DIR}" ]]; then
        mkdir -p "${BASH_LOG_DIR}" || {
            echo "Failed to create directory: ${BASH_LOG_DIR}"
            exit 1
        }
        info "Created directory: ${BASH_LOG_DIR}"
    fi

    # MENU Files
    export CONFIG_FILE="${SCRIPT_DIR}/config/config.sh"
    export MENU_FILE="${SCRIPT_DIR}/lib/menu.sh"
    export LOG_FILE="${SCRIPT_DIR}/setup.log"
    export MENU_TIMESTAMP_FILE="${SCRIPT_DIR}/menu_timestamps"

    # Ensure the timestamp file exists
    if [[ ! -f "${MENU_TIMESTAMP_FILE}" ]]; then
        touch "${MENU_TIMESTAMP_FILE}"
    fi

    # ###########################################
    # PENTEST PATHS
    # ###########################################

    # PENTEST CONFIG FILES
    export PENTEST_ENV_FILE="${BASH_DIR}/pentest.env.sh"
    export PENTEST_ALIAS_FILE="${BASH_DIR}/pentest.alias.sh"
    export PENTEST_KEYS_FILE="${BASH_DIR}/pentest.keys"
    export PENTEST_LOG_FILE="${BASH_DIR}/pentest.log"
    export PENTEST_MENU_TIMESTAMP_FILE="${BASH_DIR}/pentest_menu_timestamps"

    # Ensure the timestamp file exists
    if [[ ! -f "${PENTEST_MENU_TIMESTAMP_FILE}" ]]; then
        touch "${PENTEST_MENU_TIMESTAMP_FILE}"
    fi

    # DATA_DIR
    export DATA_DIR="${HOME}/DATA"
    export TOOLS_DIR="${DATA_DIR}/TOOLS"
    export LOGS_DIR="${DATA_DIR}/LOGS"

    # ENGAGEMENT_DIR
    export ENGAGEMENT_DIR="${DATA_DIR}"
    export BACKUP_DIR="${ENGAGEMENT_DIR}/BACKUP"
    export RECON_DIR="${ENGAGEMENT_DIR}/RECON"
    export LOOT_DIR="${ENGAGEMENT_DIR}/LOOT"
    export CREDS_DIR="${ENGAGEMENT_DIR}/LOOT/CREDENTIALS"
    export OUTPUT_DIR="${ENGAGEMENT_DIR}/OUTPUT"
    export PORTSCAN_DIR="${OUTPUT_DIR}/PORTSCAN"
    export SHARES_DIR="${OUTPUT_DIR}/SHARES"

    # -----------------------------
    # Extra Installation Configuration
    # -----------------------------

    # Installation and compilation flags
    export INSTALL_MEATASPLOIT=false
    export INSTALL_NESSUS=false
    export SETUP_NESSUS=false
    export NESSUS_USER="pentest"
    export NESSUS_PASSWORD="123abc890XYZ"
    export COMPILE_PYTHON=false
    export INSTALL_PYTHON=true

    # Python version
    export PYTHON_VERSION="3.12"

    # LOG FILE FOR SETUP MESSAGES
    export BASH_LOG_FILE="${BASH_DIR}/bash_setup.log"
fi
