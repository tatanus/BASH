#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : pre2k.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

function install_pre2k() {
    # Define the arguments
    TOOL_NAME="pre2k"
    GIT_URL="https://github.com/garrettfoster13/pre2k-TS.git"
    REQUIREMENTS_FILE="requirements.txt"
    PIP_INSTALLS=("rich" "pycryptodome")

    # Call the function
    _Install_Git_Python_Tool "${TOOL_NAME}" "${GIT_URL}" false "${REQUIREMENTS_FILE}" "${PIP_INSTALLS[@]}"

    _Del_Alias "pre2k.py"
    _Del_Alias "pre2k"
    _Add_Alias "function pre2k.py { (cd ${TOOLS_DIR}/pre2k-TS && ${TOOLS_DIR}/pre2k-TS/venv/bin/${PYTHON} ${TOOLS_DIR}/pre2k-TS/pre2k.py) }"
    _Add_Alias "function pre2k { (cd ${TOOLS_DIR}/pre2k-TS && ${TOOLS_DIR}/pre2k-TS/venv/bin/${PYTHON} ${TOOLS_DIR}/pre2k-TS/pre2k.py) }"
}

# Test function for pre2k
function test_pre2k() {
    local TOOL_NAME="pre2k"
    local TOOL_COMMAND="pre2k -h"
    AppTest "${TOOL_NAME}" "${TOOL_COMMAND}" 1
    local status=$?

    # Return the status from AppTest
    return "${status}"
}
