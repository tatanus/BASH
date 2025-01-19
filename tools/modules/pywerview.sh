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
    TOOL_NAME="pywerview.py"
    GIT_URL="https://github.com/the-useless-one/pywerview"
    REQUIREMENTS_FILE=""
    PIP_INSTALLS=("bs4")
    #PIP_INSTALLS=(".")

    # Call the function
    _Install_Git_Python_Tool "${TOOL_NAME}" "${GIT_URL}" true "${REQUIREMENTS_FILE}" "${PIP_INSTALLS[@]}"
}

# Test function for pywerview
function test_pywerview() {
    local TOOL_NAME="pywerview.py"
    local TOOL_COMMAND="pywerview.py -h"
    AppTest "${TOOL_NAME}" "${TOOL_COMMAND}"
    local status=$?

    # Return the status from AppTest
    return "${status}"
}
