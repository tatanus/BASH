#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : donpapi.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:53:31
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:53:31  | Adam Compton | Initial creation.
# =============================================================================

tool_categories["donpapi"]="exploitation post-exploitation"

function install_donpapi() {
    _Git_Clone https://github.com/login-securite/DonPAPI.git
    _Pushd "${TOOLS_DIR}"/DonPAPI
    _Pipx_Install .
    _Popd
}

# Test function for donpapi
function test_donpapi() {
    local TOOL_NAME="donpapi"
    local TOOL_COMMAND="donpapi -h"
    AppTest "${TOOL_NAME}" "${TOOL_COMMAND}"
    local status=$?

    # Return the status from AppTest
    return "${status}"
}
