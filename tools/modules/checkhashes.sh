#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : checkhashes.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

function install_checkhashes() {
    # Create directory for CheckHashes
    mkdir -p "${TOOLS_DIR}/CheckHashes"

    # Download check_hashes.py
    if ! _Curl "https://gist.githubusercontent.com/bandrel/3dd47c93cd430606865ec84d281913dc/raw/e9298bd831c214f2bea265137ec276fe3d7bbc28/check_hashes.py" "${TOOLS_DIR}/CheckHashes/check_hashes.py"; then
        fail "Failed to download check_hashes.py."
        return "${_FAIL}"
    fi

    # Add aliases for check_hashes
    _Add_Alias "alias check_hashes.py='${PYTHON} ${TOOLS_DIR}/CheckHashes/check_hashes.py'"
    _Add_Alias "alias check_hashes='${PYTHON} ${TOOLS_DIR}/CheckHashes/check_hashes.py'"
    success "check_hashes installed and aliases added successfully."
}

# Test function for checkhashes
function test_checkhashes() {
    local TOOL_NAME="checkhashes"
    local TOOL_COMMAND="check_hashes -h"
    AppTest "${TOOL_NAME}" "${TOOL_COMMAND}"
    local status=$?

    # Return the status from AppTest
    return "${status}"
}