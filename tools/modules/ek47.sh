#!/usr/bin/env bash

# =============================================================================
# NAME        : ek47.sh
# DESCRIPTION : 
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

function install_ek47() {
    # Define the arguments
    TOOL_NAME="ek47"
    GIT_URL="https://gitlab.com/KevinJClark/ek47.git"
    REQUIREMENTS_FILE="requirements.txt"
    PIP_INSTALLS=()

    # Call the function
    _Install_Git_Python_Tool "${TOOL_NAME}" "${GIT_URL}" false "${REQUIREMENTS_FILE}" "${PIP_INSTALLS[@]}"

    _Del_Alias "ek47.py"
    _Del_Alias "ek47"
    _Add_Alias "function ek47.py { (cd ${TOOLS_DIR}/ek47 && ${TOOLS_DIR}/ek47/venv/bin/${PYTHON} ${TOOLS_DIR}/ek47/ek47.py) }"
    _Add_Alias "function ek47 { (cd ${TOOLS_DIR}/ek47 && ${TOOLS_DIR}/ek47/venv/bin/${PYTHON} ${TOOLS_DIR}/ek47/ek47.py) }"
}

# Test function for ek47
function test_ek47() {
    local TOOL_NAME="ek47"
    local TOOL_COMMAND="ek47 -h"
    AppTest "${TOOL_NAME}" "${TOOL_COMMAND}"
    local status=$?

    # Return the status from AppTest
    return "${status}"
}
