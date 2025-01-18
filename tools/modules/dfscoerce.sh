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
    TOOL_NAME="dfscoerce.py"
    GIT_URL="https://github.com/Wh04m1001/DFSCoerce.git"
    REQUIREMENTS_FILE=""
    PIP_INSTALLS=()

    # Call the function
    _Install_Git_Python_Tool "${TOOL_NAME}" "${GIT_URL}" true "${REQUIREMENTS_FILE}" "${PIP_INSTALLS[@]}"
}

# Test function for dfscoerce
function test_dfscoerce() {
    local TOOL_NAME="dfscoerce.py"
    local TOOL_COMMAND="dfscoerce.py -h"
    AppTest "${TOOL_NAME}" "${TOOL_COMMAND}" 2
    local status=$?

    # Return the status from AppTest
    return "${status}"
}
