#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : servicedetector.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

function install_servicedetector() {
    # Define the arguments
    TOOL_NAME="serviceDetector"
    GIT_URL="https://github.com/tothi/serviceDetector.git"
    REQUIREMENTS_FILE=""
    PIP_INSTALLS=()

    # Call the function
    _Install_Git_Python_Tool "${TOOL_NAME}" "${GIT_URL}" true "${REQUIREMENTS_FILE}" "${PIP_INSTALLS[@]}"
}

# Test function for servicedetector
function test_servicedetector() {
    local TOOL_NAME="servicedetector"
    local TOOL_COMMAND="serviceDetector -h"
    AppTest "${TOOL_NAME}" "${TOOL_COMMAND}" 1
    local status=$?

    # Return the status from AppTest
    return "${status}"
}
