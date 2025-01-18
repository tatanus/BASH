#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : aquatone.sh
# DESCRIPTION : Installs and tests Aquatone
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

function install_aquatone() {
    _Git_Clone https://github.com/shelld3v/aquatone.git

    # Build Aquatone binary
    _Pushd "${TOOLS_DIR}/aquatone" || return 1
    if ! GOOS=linux GOARCH=amd64 go build -o aquatone; then
        fail "Failed to build Aquatone."
        _Popd
        return "${_FAIL}"
    fi
    _Popd

    # Add alias for Aquatone
    _add_tool_function "aquatone" "aquatone/aquatone"
    pass "Aquatone installed and alias added successfully."
}

# Test function for aquatone
function test_aquatone() {
    local TOOL_NAME="aquatone"
    local TOOL_COMMAND="aquatone -h"
    AppTest "${TOOL_NAME}" "${TOOL_COMMAND}"
    local status=$?

    # Return the status from AppTest
    return "${status}"
}
