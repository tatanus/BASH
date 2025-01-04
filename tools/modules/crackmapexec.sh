#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : crackmapexec.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:53:29
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:53:29  | Adam Compton | Initial creation.
# =============================================================================

function install_crackmapexec() {
    _Git_Clone https://github.com/byt3bl33d3r/CrackMapExec.git
    _Pushd "${TOOLS_DIR}"/CrackMapExec
    _Pipx_Install .
    _Popd
}

# Test function for crackmapexec
function test_crackmapexec() {
    local TOOL_NAME="crackmapexec"
    local TOOL_COMMAND="cme -h"
    AppTest "${TOOL_NAME}" "${TOOL_COMMAND}"
    local status=$?

    # Return the status from AppTest
    return "${status}"
}
