#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : ridenum.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

function install_ridenum() {
    # Define the arguments
    TOOL_NAME="ridenum"
    GIT_URL="https://github.com/trustedsec/ridenum.git"
    REQUIREMENTS_FILE=""
    PIP_INSTALLS=()

    # Call the function
    _Install_Git_Python_Tool "${TOOL_NAME}" "${GIT_URL}" false "${REQUIREMENTS_FILE}" "${PIP_INSTALLS[@]}"
}

# Test function for ridenum
function test_ridenum() {
    local TOOL_NAME="ridenum"
    local TOOL_COMMAND="ridenum -h"
    AppTest "${TOOL_NAME}" "${TOOL_COMMAND}"
    local status=$?

    # Return the status from AppTest
    return "${status}"
}
