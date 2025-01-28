#!/usr/bin/env bats

# =============================================================================
# NAME        : test_utils_sh.bats
# DESCRIPTION : BATS unit tests for utils.sh script to verify dynamic sourcing
#               of utility scripts and validation of the lib directory.
# =============================================================================

# Stub logging functions
fail() { echo "[FAIL] $*"; }
pass() { echo "[PASS] $*"; }
info() { echo "[INFO] $*"; }
warn() { echo "[WARN] $*"; }
debug() { echo "[DEBUG] $*"; }

# =============================================================================
# Setup: Create the test environment
# -----------------------------------------------------------------------------
# 1. Creates a temporary directory (SCRIPT_DIR).
# 2. Populates SCRIPT_DIR with mock utility scripts and dependencies (config.sh, lists.sh, utils.sh).
# =============================================================================
setup() {
    info "Setting up test environment"

    # Define the base directory
    BASE_DIR="$(pwd)"
    export BASE_DIR

    # Create a temporary SCRIPT_DIR for the test environment
    export SCRIPT_DIR=$(mktemp -d)

    # Create necessary subdirectories
    mkdir -p "${SCRIPT_DIR}/lib" "${SCRIPT_DIR}/config"

    # Add mock utility scripts
    cat <<'EOF' > "${SCRIPT_DIR}/lib/utils_mock1.sh"
#!/usr/bin/env bash
declare -g MOCK1_LOADED=true
EOF

    cat <<'EOF' > "${SCRIPT_DIR}/lib/utils_mock2.sh"
#!/usr/bin/env bash
declare -g MOCK2_LOADED=true
EOF

    chmod +x "${SCRIPT_DIR}/lib/"utils_mock*.sh

    # Copy required files to SCRIPT_DIR
    cp "${BASE_DIR}/lib/utils.sh" "${SCRIPT_DIR}/lib/utils.sh" || { fail "utils.sh not found in ${BASE_DIR}/lib"; return 1; }
    cp "${BASE_DIR}/lib/lists.sh" "${SCRIPT_DIR}/lib/lists.sh" || { fail "lists.sh not found in ${BASE_DIR}/lib"; return 1; }
    cp "${BASE_DIR}/config/config.sh" "${SCRIPT_DIR}/config/config.sh" || { fail "config.sh not found in ${BASE_DIR}/config"; return 1; }

    # Source required scripts
    source "${SCRIPT_DIR}/config/config.sh" || { fail "Failed to source config.sh"; return 1; }
    source "${SCRIPT_DIR}/lib/lists.sh" || { fail "Failed to source lists.sh"; return 1; }

    pass "Setup complete"
}

# =============================================================================
# Teardown: Clean up the test environment
# -----------------------------------------------------------------------------
# Removes the temporary SCRIPT_DIR created during the setup phase.
# =============================================================================
teardown() {
    rm -rf "${SCRIPT_DIR}"
    pass "Cleaned up test environment"
}

# =============================================================================
# Test: Verify UTILS_SH_LOADED guard is set
# -----------------------------------------------------------------------------
# Ensures that utils.sh sets the UTILS_SH_LOADED guard variable when sourced.
# =============================================================================
@test "Verify UTILS_SH_LOADED guard is set" {
    source "${SCRIPT_DIR}/lib/utils.sh" || { fail "Failed to source utils.sh"; return 1; }
    [ "${UTILS_SH_LOADED:-}" == "true" ] || { fail "UTILS_SH_LOADED is not set"; return 1; }
    pass "UTILS_SH_LOADED guard is correctly set"
}

# =============================================================================
# Test: Verify dynamic sourcing of utility scripts
# -----------------------------------------------------------------------------
# Confirms that utils.sh dynamically sources all `utils_*.sh` scripts in the lib directory.
# =============================================================================
@test "Verify dynamic sourcing of utils_*.sh scripts" {
    source "${SCRIPT_DIR}/lib/utils.sh" || { fail "Failed to source utils.sh"; return 1; }
    [ "${MOCK1_LOADED:-false}" == "true" ] || { fail "MOCK1_LOADED is not set"; return 1; }
    [ "${MOCK2_LOADED:-false}" == "true" ] || { fail "MOCK2_LOADED is not set"; return 1; }
    pass "All utils_*.sh scripts were sourced successfully"
}

# =============================================================================
# Test: Verify graceful handling of no utils_*.sh scripts
# -----------------------------------------------------------------------------
# Ensures that utils.sh handles the absence of `utils_*.sh` scripts gracefully without errors.
# =============================================================================
@test "Verify graceful handling of no utils_*.sh scripts" {
    # Remove all utils_*.sh scripts
    rm -f "${SCRIPT_DIR}/lib/utils_*.sh"

    # Run utils.sh and capture output
    output=$(bash "${SCRIPT_DIR}/lib/utils.sh" 2>&1)
    status=$?

    # Verify script does not fail
    [ "$status" -eq 0 ] || { fail "utils.sh failed unexpectedly"; return 1; }

    # Verify no unexpected sourcing messages are present
    [[ ! "$output" =~ "Sourced:" ]] || { fail "Unexpected sourcing output: $output"; return 1; }
    pass "utils.sh handled no utils_*.sh scripts gracefully"
}