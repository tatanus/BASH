#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : ldapper.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

function install_ldapper() {
    # Define the arguments
    TOOL_NAME="ldapper"
    GIT_URL="https://github.com/shellster/LDAPPER.git"
    REQUIREMENTS_FILE="requirements.txt"
    PIP_INSTALLS=()

    # Call the function
    _Install_Git_Python_Tool "${TOOL_NAME}" "${GIT_URL}" false "${REQUIREMENTS_FILE}" "${PIP_INSTALLS[@]}"
}

# Test function for ldapper
function test_ldapper() {
    local TOOL_NAME="ldapper"
    local TOOL_COMMAND="ldapper -h"
    AppTest "${TOOL_NAME}" "${TOOL_COMMAND}"
    local status=$?

    # Return the status from AppTest
    return "${status}"
}
