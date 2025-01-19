#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : timeroast.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

function install_timeroast() {
    # Define the arguments
    TOOL_NAME="timeroast.py"
    GIT_URL="https://github.com/SecuraBV/Timeroast.git"
    REQUIREMENTS_FILE=""
    PIP_INSTALLS=()

    # Call the function
    _Install_Git_Python_Tool "${TOOL_NAME}" "${GIT_URL}" false "${REQUIREMENTS_FILE}" "${PIP_INSTALLS[@]}"
}

# Test function for timeroast
function test_timeroast() {
    local TOOL_NAME="timeroast.py"
    local TOOL_COMMAND="timeroast.py -h"
    AppTest "${TOOL_NAME}" "${TOOL_COMMAND}"
    local status=$?

    # Return the status from AppTest
    return "${status}"
}
