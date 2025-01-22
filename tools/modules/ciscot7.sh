#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : ciscot7.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

tool_categories["ciscot7"]="password-recovery"

function install_ciscot7() {
    # Define the arguments
    TOOL_NAME="ciscot7.py"
    GIT_URL="https://github.com/theevilbit/ciscot7.git"
    REQUIREMENTS_FILE=""
    PIP_INSTALLS=()

    # Call the function
    _Install_Git_Python_Tool "${TOOL_NAME}" "${GIT_URL}" false "${REQUIREMENTS_FILE}" "${PIP_INSTALLS[@]}"
}

# Test function for ciscot7
function test_ciscot7() {
    local TOOL_NAME="ciscot7.py"
    local TOOL_COMMAND="ciscot7.py --help"
    AppTest "${TOOL_NAME}" "${TOOL_COMMAND}"
    local status=$?

    # Return the status from AppTest
    return "${status}"
}
