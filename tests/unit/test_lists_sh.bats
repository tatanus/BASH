#!/usr/bin/env bats

# =============================================================================
# NAME        : test_lists_sh.bats
# DESCRIPTION : BATS unit tests for verifying variables, arrays, and mappings
#               declared in the lists.sh script.
# DEPENDENCIES: Requires config.sh to be sourced before lists.sh.
# =============================================================================

# =============================================================================
# Setup: Load the config.sh and lists.sh scripts
# -----------------------------------------------------------------------------
# 1. Defines the SCRIPT_DIR variable to point to the current directory.
# 2. Sources the config.sh and lists.sh scripts.
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

    # Source lists.sh
    if [[ -f "${SCRIPT_DIR}/lib/lists.sh" ]]; then
        source "${SCRIPT_DIR}/lib/lists.sh"
    else
        echo "lists.sh not found." >&2
        exit 1
    fi
}

# =============================================================================
# Test: Ensure the LISTS_SH_LOADED guard is set
# -----------------------------------------------------------------------------
# Validates that the lists.sh script sets the LISTS_SH_LOADED guard variable.
# =============================================================================
@test "Verify LISTS_SH_LOADED guard is set" {
    [ "${LISTS_SH_LOADED:-}" == "true" ]
}

# =============================================================================
# Test: Validate critical environment variables
# -----------------------------------------------------------------------------
# Confirms that critical environment variables are set and not empty.
# =============================================================================
@test "Verify essential environment variables are set" {
    [ -n "${DATA_DIR:-}" ]
    [ -n "${ENGAGEMENT_DIR:-}" ]
    [ -n "${TOOLS_DIR:-}" ]
}

# =============================================================================
# Test: Verify required arrays are declared and non-empty
# -----------------------------------------------------------------------------
# Checks that various arrays in lists.sh are declared and contain elements.
# =============================================================================

@test "Verify PENTEST_REQUIRED_DIRECTORIES array is declared" {
    [ "${#PENTEST_REQUIRED_DIRECTORIES[@]}" -gt 0 ]
}

@test "Verify ENGAGEMENT_REQUIRED_DIRECTORIES array is declared" {
    [ "${#ENGAGEMENT_REQUIRED_DIRECTORIES[@]}" -gt 0 ]
}

@test "Verify NECESSARY_ENGAGEMENT_FILES array is declared" {
    [ "${#NECESSARY_ENGAGEMENT_FILES[@]}" -gt 0 ]
}

@test "Verify TOOL_CONFIG_FILES array is declared" {
    [ "${#TOOL_CONFIG_FILES[@]}" -gt 0 ]
}

@test "Verify COMMON_DOT_FILES array is declared" {
    [ "${#COMMON_DOT_FILES[@]}" -gt 0 ]
}

@test "Verify BASH_DOT_FILES array is declared" {
    [ "${#BASH_DOT_FILES[@]}" -gt 0 ]
}

@test "Verify PENTEST_FILES array is declared" {
    [ "${#PENTEST_FILES[@]}" -gt 0 ]
}

@test "Verify APT_PACKAGES array is declared" {
    [ "${#APT_PACKAGES[@]}" -gt 0 ]
}

@test "Verify PIP_PACKAGES array is declared" {
    [ "${#PIP_PACKAGES[@]}" -gt 0 ]
}

@test "Verify PIPX_PACKAGES array is declared" {
    [ "${#PIPX_PACKAGES[@]}" -gt 0 ]
}

@test "Verify GO_TOOLS array is declared" {
    [ "${#GO_TOOLS[@]}" -gt 0 ]
}

@test "Verify RUBY_GEMS array is declared" {
    [ "${#RUBY_GEMS[@]}" -gt 0 ]
}

# =============================================================================
# Test: Validate mappings and debug associative arrays
# -----------------------------------------------------------------------------
# Confirms that associative arrays like APP_TESTS and TOOL_CATEGORY_MAP exist
# and displays their content for debugging.
# =============================================================================

@test "Debug APP_TESTS declaration" {
    run declare -p APP_TESTS 2>/dev/null || echo "APP_TESTS is not declared in the test context"
    echo "$output"
}

@test "Debug TOOL_CATEGORY_MAP declaration" {
    run declare -p TOOL_CATEGORY_MAP 2>/dev/null || echo "TOOL_CATEGORY_MAP is not declared in the test context"
    echo "$output"
}

@test "Verify TOOL_CATEGORIES array is declared" {
    [ "${#TOOL_CATEGORIES[@]}" -gt 0 ]
}

# =============================================================================
# Test: Validate MENU arrays
# -----------------------------------------------------------------------------
# Ensures that menu arrays are declared and contain elements.
# =============================================================================

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