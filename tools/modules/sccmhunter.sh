#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : sccmhunter.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

function install_sccmhunter() {
    # Define the arguments
    TOOL_NAME="sccmhunter.py"
    GIT_URL="https://github.com/garrettfoster13/sccmhunter.git"
    REQUIREMENTS_FILE="requirements.txt"
    PIP_INSTALLS=()

    # Call the function
    _Install_Git_Python_Tool "${TOOL_NAME}" "${GIT_URL}" false "${REQUIREMENTS_FILE}" "${PIP_INSTALLS[@]}"
}

# Test function for sccmhunter
function test_sccmhunter() {
    local TOOL_NAME="sccmhunter.py"
    local TOOL_COMMAND="sccmhunter.py -h"
    AppTest "${TOOL_NAME}" "${TOOL_COMMAND}" 2
    local status=$?

    # Return the status from AppTest
    return "${status}"
}
