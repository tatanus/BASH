#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : pretender.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:53:44
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:53:44  | Adam Compton | Initial creation.
# =============================================================================

function install_pretender() {
    _Git_Clone https://github.com/RedTeamPentesting/pretender.git
    _Pushd "${TOOLS_DIR}"/pretender
    go build
    _Popd

    _Add_Alias "alias pretender='${TOOLS_DIR}/pretender/pretender'"
}

# Test function for pretender
function test_pretender() {
    local TOOL_NAME="pretender"
    local TOOL_COMMAND="pretender -h"
    AppTest "${TOOL_NAME}" "${TOOL_COMMAND}" 2
    local status=$?

    # Return the status from AppTest
    return "${status}"
}
