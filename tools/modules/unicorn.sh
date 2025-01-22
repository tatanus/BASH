#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : unicorn.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2025-01-01 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2025-01-01 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

tool_categories["unicorn"]="post-exploitation"

function install_unicorn() {
    # Define the arguments
    TOOL_NAME="unicorn.py"
    GIT_URL="https://github.com/trustedsec/unicorn.git"
    REQUIREMENTS_FILE=""
    PIP_INSTALLS=()

    # Call the function
    _Install_Git_Python_Tool "${TOOL_NAME}" "${GIT_URL}" false "${REQUIREMENTS_FILE}" "${PIP_INSTALLS[@]}"
}

# Test function for unicorn
function test_unicorn() {
    local TOOL_NAME="unicorn.py"
    local TOOL_COMMAND="unicorn.py -h"
    AppTest "${TOOL_NAME}" "${TOOL_COMMAND}"
    local status=$?

    # Return the status from AppTest
    return "${status}"
}
