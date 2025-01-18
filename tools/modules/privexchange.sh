#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : privexchange.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

function install_privexchange() {
    # Define the arguments
    TOOL_NAME="privexchange.py"
    GIT_URL="https://github.com/dirkjanm/PrivExchange"
    REQUIREMENTS_FILE="requirements.txt"
    PIP_INSTALLS=()

    # Call the function
    _Install_Git_Python_Tool "${TOOL_NAME}" "${GIT_URL}" false "${REQUIREMENTS_FILE}" "${PIP_INSTALLS[@]}"
}

# Test function for privexchange
function test_privexchange() {
    local TOOL_NAME="privexchange.py"
    local TOOL_COMMAND="privexchange.py -h"
    AppTest "${TOOL_NAME}" "${TOOL_COMMAND}" 2
    local status=$?

    # Return the status from AppTest
    return "${status}"
}
