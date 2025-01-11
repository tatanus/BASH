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

function install_krbrelayx() {
    # Define the arguments
    TOOL_NAME="krbrelayx"
    GIT_URL="https://github.com/dirkjanm/krbrelayx.git"
    REQUIREMENTS_FILE="requires.txt"
    PIP_INSTALLS=()

    # Call the function
    _Install_Git_Python_Tool "${TOOL_NAME}" "${GIT_URL}" true "${REQUIREMENTS_FILE}" "${PIP_INSTALLS[@]}"

    # Add additional aliases
    _Del_Alias "dnstool.py"
    _Del_Alias "dnstool"
    _Add_Alias "alias dnstool.py='${TOOLS_DIR}/krbrelayx/venv/bin/${PYTHON} ${TOOLS_DIR}/krbrelayx/dnstool.py'"
    _Add_Alias "alias dnstool='${TOOLS_DIR}/krbrelayx/venv/bin/${PYTHON} ${TOOLS_DIR}/krbrelayx/dnstool.py'"
}

# Test function for krbrelayx
function test_krbrelayx() {
    local TOOL_NAME="krbrelayx"
    local TOOL_COMMAND="krbrelayx -h"
    AppTest "${TOOL_NAME}" "${TOOL_COMMAND}" 2
    local status=$?

    # Return the status from AppTest
    return "${status}"
}
