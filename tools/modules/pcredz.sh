#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : pcredz.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

tool_categories["pcredz"]="intelligence-gathering"

function install_pcredz() {
    # Define the arguments
    TOOL_NAME="Pcredz"
    GIT_URL="https://github.com/lgandx/PCredz.git"
    REQUIREMENTS_FILE=""
    PIP_INSTALLS=("Cython" "python-libpcap")

    # Call the function
    _Install_Git_Python_Tool "${TOOL_NAME}" "${GIT_URL}" false "${REQUIREMENTS_FILE}" "${PIP_INSTALLS[@]}"
}

# Test function for pcredz
function test_pcredz() {
    local TOOL_NAME="Pcredz"
    local TOOL_COMMAND="Pcredz -h"
    AppTest "${TOOL_NAME}" "${TOOL_COMMAND}"
    local status=$?

    # Return the status from AppTest
    return "${status}"
}
