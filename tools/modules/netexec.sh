#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : netexec.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:53:41
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:53:41  | Adam Compton | Initial creation.
# =============================================================================

tool_categories["netexec"]="exploitation"

function install_netexec() {
    info "netexec is installed via pipx"
    return
    # _Git_Clone https://github.com/Pennyw0rth/NetExec.git
    # _Pushd "${TOOLS_DIR}"/NetExec
    # _Pipx_Install .
    # _Popd
}

# Test function for netexec
function test_netexec() {
    local TOOL_NAME="netexec"
    local TOOL_COMMAND="nxc -h"
    AppTest "${TOOL_NAME}" "${TOOL_COMMAND}"
    local status=$?

    # Return the status from AppTest
    return "${status}"
}
