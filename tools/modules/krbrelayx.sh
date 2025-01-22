#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : krbrelayx.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

tool_categories["krbrelayx"]="post-exploitation"

function install_krbrelayx() {
    # Define the arguments
    TOOL_NAME="krbrelayx.py"
    GIT_URL="https://github.com/dirkjanm/krbrelayx.git"
    REQUIREMENTS_FILE="requires.txt"
    PIP_INSTALLS=()

    # Call the function
    _Install_Git_Python_Tool "${TOOL_NAME}" "${GIT_URL}" true "${REQUIREMENTS_FILE}" "${PIP_INSTALLS[@]}"

    # Add additional aliases
    _add_tool_function "dnstool.py" "krbrelayx/dnstool.py"
}

# Test function for krbrelayx
function test_krbrelayx() {
    local TOOL_NAME="krbrelayx.py"
    local TOOL_COMMAND="krbrelayx.py -h"
    AppTest "${TOOL_NAME}" "${TOOL_COMMAND}"
    local status=$?

    # Return the status from AppTest
    return "${status}"
}
