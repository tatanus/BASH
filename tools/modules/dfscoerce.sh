#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : dfscoerce.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

function install_dfscoerce() {
    # Define the arguments
    TOOL_NAME="dfscoerce"
    GIT_URL="https://github.com/Wh04m1001/DFSCoerce.git"
    REQUIREMENTS_FILE=""
    PIP_INSTALLS=()

    # Call the function
    _Install_Git_Python_Tool "${TOOL_NAME}" "${GIT_URL}" true "${REQUIREMENTS_FILE}" "${PIP_INSTALLS[@]}"
}

# Test function for dfscoerce
function test_dfscoerce() {
    local TOOL_NAME="dfscoerce"
    local TOOL_COMMAND="dfscoerce -h"
    AppTest "${TOOL_NAME}" "${TOOL_COMMAND}"
    local status=$?

    # Return the status from AppTest
    return "${status}"
}
