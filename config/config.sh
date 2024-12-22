#!/usr/bin/env bash

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
    export DEBUG=true

    # pass/fail/true/fall variables
    export _PASS=0
    export _FAIL=1

    # Enable proxychains4 for certain commands (true/false)
    export PROXYCHAINS_CMD="proxychains4 -q "

    # Proxychains4 configuration file
    export PROXYCHAINS_CONFIG="/etc/proxychains4.conf"

    # Interactive menu
    export INTERACTIVE_MENU=false

    # Directories
    export BASE_DIR="$MY_HOME/DATA"
    export TOOL_DIR="$BASE_DIR/TOOLS"
    export LOG_DIR="$BASE_DIR/LOGS"

    export PENTEST_DIR="$HOME/.pentest"

    # Files
    export CONFIG_FILE="$SCRIPT_DIR/config/config.sh"
    export ENV_FILE="$PENTEST_DIR/pentest.env"
    export ALIAS_FILE="$PENTEST_DIR/pentest.alias"
    export KEYS_FILE="$PENTEST_DIR/pentest.keys"

    #export LOG_FILE="$PENTEST_DIR/pentest.log"
    export LOG_FILE="$PENTEST_DIR/install.log"

    export MENU_TIMESTAMP_FILE="$PENTEST_DIR/menu_timestamps"
    export MENU_FILE="$SCRIPT_DIR/lib/menu.sh"

    # Ensure the PENTEST directory exists
    if [ ! -d "$PENTEST_DIR" ]; then
        mkdir -p "$PENTEST_DIR" || {
            echo "Failed to create directory: $PENTEST_DIR"
            exit 1
        }
        info "Created directory: $PENTEST_DIR"
    fi

    # Ensure the timestamp file exists
    if [ ! -f "$MENU_TIMESTAMP_FILE" ]; then
        touch "$MENU_TIMESTAMP_FILE"
    fi

    # -----------------------------
    # API/License Keys Configuration
    # -----------------------------

    if [[ -f "$KEYS_FILE" ]]; then
        source "$KEYS_FILE"
    else
        echo "File not found: $KEYS_FILE. Skipping sourcing."
    fi

    # -----------------------------
    # Extra Installation Configuration
    # -----------------------------

    # Installation and compilation flags
    export INSTALL_MEATASPLOIT=false
    export INSTALL_NESSUS=false
    export SETUP_NESSUS=false
    export COMPILE_PYTHON=false
    export INSTALL_PYTHON=true

    # Python version
    export PYTHON_VERSION="3.12"

    # LOG FILE FOR SETUP MESSAGES
    export BASH_LOG_FILE="$PENTEST_DIR/bash_setup.log"
fi