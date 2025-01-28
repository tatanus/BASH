#!/usr/bin/env bats

# =============================================================================
# NAME        : test_config.bats
# DESCRIPTION : BATS unit tests for verifying environment variables declared in
#               config.sh.
# AUTHOR      : Adam Compton
# DATE CREATED: 2025-01-27
# =============================================================================

# =============================================================================
# Setup: Load the config.sh script
# -----------------------------------------------------------------------------
# 1. Defines the SCRIPT_DIR variable pointing to the current directory.
# 2. Sources config.sh to make its variables available for testing.
# =============================================================================
setup() {
    SCRIPT_DIR="$(pwd)"
    export SCRIPT_DIR

    # Source config.sh
    if [[ -f "${SCRIPT_DIR}/config/config.sh" ]]; then
        source "${SCRIPT_DIR}/config/config.sh"
    else
        echo "config.sh not found." >&2
        exit 1
    fi
}

# =============================================================================
# Tests for config.sh
# -----------------------------------------------------------------------------
# Validate that environment variables declared in config.sh are set correctly.
# =============================================================================

# =============================================================================
# Test: Verify CONFIG_SH_LOADED is set
# -----------------------------------------------------------------------------
# Ensures the CONFIG_SH_LOADED guard variable is set to "true" after sourcing
# config.sh.
# =============================================================================
@test "Ensure CONFIG_SH_LOADED is set" {
    run bash -c "[[ \"${CONFIG_SH_LOADED}\" == \"true\" ]]"
    [ "$status" -eq 0 ]
}

# =============================================================================
# Test: Validate essential environment variables
# -----------------------------------------------------------------------------
# Checks that all essential environment variables are set and not empty.
# =============================================================================
@test "Verify essential environment variables exist and are not empty" {
    # List of essential variables to check
    essential_vars=(
        "DEBUG"
        "NO_DISPLAY"
        "_PASS"
        "_FAIL"
        "PROXYCHAINS_CMD"
        "PROXYCHAINS_CONFIG"
        "INTERACTIVE_MENU"
        "BASH_DIR"
        "BASH_LOG_DIR"
        "CONFIG_FILE"
        "MENU_FILE"
        "LOG_FILE"
        "MENU_TIMESTAMP_FILE"
        "PENTEST_ENV_FILE"
        "PENTEST_ALIAS_FILE"
        "PENTEST_KEYS_FILE"
        "PENTEST_LOG_FILE"
        "PENTEST_MENU_TIMESTAMP_FILE"
        "DATA_DIR"
        "TOOLS_DIR"
        "LOGS_DIR"
        "ENGAGEMENT_DIR"
        "BACKUP_DIR"
        "RECON_DIR"
        "LOOT_DIR"
        "CREDS_DIR"
        "OUTPUT_DIR"
        "PORTSCAN_DIR"
        "SHARES_DIR"
        "INSTALL_METASPLOIT"
        "INSTALL_NESSUS"
        "SETUP_NESSUS"
        "NESSUS_USER"
        "NESSUS_PASSWORD"
        "COMPILE_PYTHON"
        "INSTALL_PYTHON"
        "PYTHON_VERSION"
        "BASH_LOG_FILE"
    )

    for var in "${essential_vars[@]}"; do
        run bash -c "[[ -n \${${var}:-} ]]"
        [ "$status" -eq 0 ]
    done
}

# =============================================================================
# Test: Validate DEBUG variable
# -----------------------------------------------------------------------------
# Ensures that the DEBUG variable is set to a valid boolean value ("true" or
# "false").
# =============================================================================
@test "Verify DEBUG variable is set to a valid boolean value" {
    run bash -c "[[ \"${DEBUG}\" == \"true\" || \"${DEBUG}\" == \"false\" ]]"
    [ "$status" -eq 0 ]
}

# =============================================================================
# Test: Validate PROXYCHAINS_CMD
# -----------------------------------------------------------------------------
# Confirms that the PROXYCHAINS_CMD variable contains "proxychains4".
# =============================================================================
@test "Verify PROXYCHAINS_CMD contains 'proxychains4'" {
    [[ "${PROXYCHAINS_CMD}" == *"proxychains4"* ]]
}

# =============================================================================
# Test: Validate PYTHON_VERSION
# -----------------------------------------------------------------------------
# Checks that the PYTHON_VERSION variable is set and not empty.
# =============================================================================
@test "Verify PYTHON_VERSION is set and not empty" {
    [[ -n "${PYTHON_VERSION}" ]]
}

# =============================================================================
# Test: Validate INSTALL_PYTHON variable
# -----------------------------------------------------------------------------
# Ensures that INSTALL_PYTHON is set to a valid boolean value ("true" or
# "false").
# =============================================================================
@test "Verify INSTALL_PYTHON is set to a valid boolean value" {
    run bash -c "[[ \"${INSTALL_PYTHON}\" == \"true\" || \"${INSTALL_PYTHON}\" == \"false\" ]]"
    [ "$status" -eq 0 ]
}

# =============================================================================
# Test: Validate Nessus credentials
# -----------------------------------------------------------------------------
# Confirms that NESSUS_USER and NESSUS_PASSWORD are set and not empty.
# =============================================================================
@test "Verify NESSUS_USER and NESSUS_PASSWORD are set and not empty" {
    [[ -n "${NESSUS_USER}" ]]
    [[ -n "${NESSUS_PASSWORD}" ]]
}