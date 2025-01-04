#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : seeyoucm_thief.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

function install_seeyoucm_thief() {
    # Define the arguments
    TOOL_NAME="thief"
    GIT_URL="https://github.com/trustedsec/SeeYouCM-Thief.git"
    REQUIREMENTS_FILE="requirements.txt"
    PIP_INSTALLS=()

    # Call the function
    _Install_Git_Python_Tool "${TOOL_NAME}" "${GIT_URL}" true "${REQUIREMENTS_FILE}" "${PIP_INSTALLS[@]}"
}

# Test function for seeyoucm_thief
function test_seeyoucm_thief() {
    local TOOL_NAME="seeyoucm_thief"
    local TOOL_COMMAND="thief -h"
    AppTest "${TOOL_NAME}" "${TOOL_COMMAND}"
    local status=$?

    # Return the status from AppTest
    return "${status}"
}
