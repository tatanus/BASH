#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : bloodhound.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

function install_bloodhound() {
    # Define the arguments
    TOOL_NAME="bloodhound.py"
    GIT_URL="https://github.com/fox-it/BloodHound.py"
    REQUIREMENTS_FILE=""
    PIP_INSTALLS=(".")

    # Call the function
    _Install_Git_Python_Tool "${TOOL_NAME}" "${GIT_URL}" false "${REQUIREMENTS_FILE}" "${PIP_INSTALLS[@]}"
}

# Test function for bloodhound
function test_bloodhound() {
    local TOOL_NAME="bloodhound.py"
    local TOOL_COMMAND="bloodhound.py -h"
    AppTest "${TOOL_NAME}" "${TOOL_COMMAND}"
    local status=$?

    # Return the status from AppTest
    return "${status}"
}
