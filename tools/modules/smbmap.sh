#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : smbmap.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:53:50
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:53:50  | Adam Compton | Initial creation.
# =============================================================================

function install_smbmap() {
    _Git_Clone https://github.com/ShawnDEvans/smbmap
    _Pushd "${TOOLS_DIR}"/smbmap
    ${PYTHON} setup.py install
    _Popd
}

# Test function for smbmap
function test_smbmap() {
    local TOOL_NAME="smbmap"
    local TOOL_COMMAND="smbmap -h"
    AppTest "${TOOL_NAME}" "${TOOL_COMMAND}"
    local status=$?

    # Return the status from AppTest
    return "${status}"
}
