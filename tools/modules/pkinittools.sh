#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : pkinittools.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

function install_pkinittools() {
    # Define the arguments
    TOOL_NAME="gettgtpkinit"
    GIT_URL="https://github.com/dirkjanm/PKINITtools.git"
    REQUIREMENTS_FILE=""
    PIP_INSTALLS=("git+https://github.com/wbond/oscrypto.git" "minikerberos")

    # Call the function
    _Install_Git_Python_Tool "${TOOL_NAME}" "${GIT_URL}" false "${REQUIREMENTS_FILE}" "${PIP_INSTALLS[@]}"

    _Del_Alias "gettgtpkinit"
    _Del_Alias "gettgtpkinit.py"
    _Add_Alias "alias gettgtpkinit='${TOOLS_DIR}/PKINITtools/venv/bin/${PYTHON} ${TOOLS_DIR}/PKINITtools/gettgtpkinit.py'"
    _Add_Alias "alias gettgtpkinit.py='${TOOLS_DIR}/PKINITtools/venv/bin/${PYTHON} ${TOOLS_DIR}/PKINITtools/gettgtpkinit.py'"
}

# Test function for pkinittools
function test_pkinittools() {
    local TOOL_NAME="pkinittools"
    local TOOL_COMMAND="gettgtpkinit -h"
    AppTest "${TOOL_NAME}" "${TOOL_COMMAND}"
    local status=$?

    # Return the status from AppTest
    return "${status}"
}
