#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : pywerview.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

function install_pywerview() {
    # Define the arguments
    TOOL_NAME="pywerview"
    GIT_URL="https://github.com/the-useless-one/pywerview"
    REQUIREMENTS_FILE="requirements.txt"
    PIP_INSTALLS=()

    # Call the function
    _Install_Git_Python_Tool "${TOOL_NAME}" "${GIT_URL}" true "${REQUIREMENTS_FILE}" "${PIP_INSTALLS[@]}"
}

# Test function for pywerview
function test_pywerview() {
    local TOOL_NAME="pywerview"
    local TOOL_COMMAND="pywerview -h"
    AppTest "${TOOL_NAME}" "${TOOL_COMMAND}"
    local status=$?

    # Return the status from AppTest
    return "${status}"
}
