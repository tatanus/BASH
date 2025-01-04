#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : spoofy.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-19 10:38:56
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-19 10:38:56  | Adam Compton | Initial creation.
# =============================================================================

function install_spoofy() {
    # Define the arguments
    TOOL_NAME="Spoofy"
    GIT_URL="https://github.com/MattKeeley/Spoofy.git"
    REQUIREMENTS_FILE="requirements.txt"
    PIP_INSTALLS=()

    # Call the function
    _Install_Git_Python_Tool "${TOOL_NAME}" "${GIT_URL}" false "${REQUIREMENTS_FILE}" "${PIP_INSTALLS[@]}"
}

# Test function for spoofy
function test_spoofy() {
    local TOOL_NAME="Spoofy"
    local TOOL_COMMAND="spoofy.py -h"
    AppTest "${TOOL_NAME}" "${TOOL_COMMAND}"
    local status=$?

    # Return the status from AppTest
    return "${status}"
}
