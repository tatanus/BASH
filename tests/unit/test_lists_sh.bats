#!/usr/bin/env bats

# =============================================================================
# NAME        : test_lists_sh.bats
# DESCRIPTION : BATS unit tests for verifying variables, arrays, and mappings
#               declared in the lists.sh script.
# DEPENDENCIES: config.sh must be sourced before lists.sh
# =============================================================================

# Setup: Load the config.sh and lists.sh scripts
setup() {
    # Load the config script for testing
    SCRIPT_DIR="$(pwd)"  # Set the current directory as the script directory
    export SCRIPT_DIR

    # Source the config.sh file
    if [[ -f "${SCRIPT_DIR}/config/config.sh" ]]; then
        source "${SCRIPT_DIR}/config/config.sh"
    else
        echo "config.sh not found." >&2
        exit 1
    fi

    # Source the lists.sh file
    if [[ -f "${SCRIPT_DIR}/lib/lists.sh" ]]; then
        source "${SCRIPT_DIR}/lib/lists.sh"
    else
        echo "lists.sh not found." >&2
        exit 1
    fi
}

# Test: Ensure the LISTS_SH_LOADED guard is set
@test "Verify LISTS_SH_LOADED guard is set" {
    [ "${LISTS_SH_LOADED}" == "true" ]
}

# Test: Validate critical environment variables
@test "Verify essential environment variables are set" {
    [ -n "${DATA_DIR}" ]
    [ -n "${ENGAGEMENT_DIR}" ]
    [ -n "${TOOLS_DIR}" ]
}

# Test: Ensure PENTEST_REQUIRED_DIRECTORIES is an array and non-empty
@test "Verify PENTEST_REQUIRED_DIRECTORIES array is declared" {
    [ "${#PENTEST_REQUIRED_DIRECTORIES[@]}" -gt 0 ]
}

# Test: Ensure ENGAGEMENT_REQUIRED_DIRECTORIES is an array and non-empty
@test "Verify ENGAGEMENT_REQUIRED_DIRECTORIES array is declared" {
    [ "${#ENGAGEMENT_REQUIRED_DIRECTORIES[@]}" -gt 0 ]
}

# Test: Ensure NECESSARY_ENGAGEMENT_FILES is an array and non-empty
@test "Verify NECESSARY_ENGAGEMENT_FILES array is declared" {
    [ "${#NECESSARY_ENGAGEMENT_FILES[@]}" -gt 0 ]
}

# Test: Ensure TOOL_CONFIG_FILES is an array and non-empty
@test "Verify TOOL_CONFIG_FILES array is declared" {
    [ "${#TOOL_CONFIG_FILES[@]}" -gt 0 ]
}

# Test: Validate DOT FILES arrays
@test "Verify COMMON_DOT_FILES array is declared" {
    [ "${#COMMON_DOT_FILES[@]}" -gt 0 ]
}

@test "Verify BASH_DOT_FILES array is declared" {
    [ "${#BASH_DOT_FILES[@]}" -gt 0 ]
}

@test "Verify PENTEST_FILES array is declared" {
    [ "${#PENTEST_FILES[@]}" -gt 0 ]
}

# Test: Validate APT_PACKAGES array
@test "Verify APT_PACKAGES array is declared" {
    [ "${#APT_PACKAGES[@]}" -gt 0 ]
}

# Test: Validate PIP_PACKAGES array
@test "Verify PIP_PACKAGES array is declared" {
    [ "${#PIP_PACKAGES[@]}" -gt 0 ]
}

# Test: Validate PIPX_PACKAGES array
@test "Verify PIPX_PACKAGES array is declared" {
    [ "${#PIPX_PACKAGES[@]}" -gt 0 ]
}

# Test: Validate GO_TOOLS array
@test "Verify GO_TOOLS array is declared" {
    [ "${#GO_TOOLS[@]}" -gt 0 ]
}

# Test: Validate RUBY_GEMS array
@test "Verify RUBY_GEMS array is declared" {
    [ "${#RUBY_GEMS[@]}" -gt 0 ]
}

@test "Debug APP_TESTS declaration" {
    run declare -p APP_TESTS 2>/dev/null || echo "APP_TESTS is not declared in the test context"
    echo "$output"
}

# Test: Validate TOOL_CATEGORIES array
@test "Verify TOOL_CATEGORIES array is declared" {
    [ "${#TOOL_CATEGORIES[@]}" -gt 0 ]
}

@test "Debug TOOL_CATEGORY_MAP declaration" {
    run declare -p TOOL_CATEGORY_MAP 2>/dev/null || echo "TOOL_CATEGORY_MAP is not declared in the test context"
    echo "$output"
}

# Test: Validate MENU arrays
@test "Verify BASH_ENVIRONMENT_MENU_ITEMS array is declared" {
    [ "${#BASH_ENVIRONMENT_MENU_ITEMS[@]}" -gt 0 ]
}

@test "Verify PENTEST_ENVIRONMENT_MENU_ITEMS array is declared" {
    [ "${#PENTEST_ENVIRONMENT_MENU_ITEMS[@]}" -gt 0 ]
}

@test "Verify SETUP_MENU_ITEMS array is declared" {
    [ "${#SETUP_MENU_ITEMS[@]}" -gt 0 ]
}

@test "Verify CONFIG_MENU_ITEMS array is declared" {
    [ "${#CONFIG_MENU_ITEMS[@]}" -gt 0 ]
}

@test "Verify INSTALL_TOOLS_MENU_ITEMS array is declared" {
    [ "${#INSTALL_TOOLS_MENU_ITEMS[@]}" -gt 0 ]
}