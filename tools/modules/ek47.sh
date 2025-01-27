#!/usr/bin/env bash
set -uo pipefail

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

TOOL_CATEGORY_MAP["ek47"]="exploitation"
APP_TESTS["ek47"]="ek47.py -h"

function install_ek47() {
    # Define the arguments
    TOOL_NAME="ek47.py"
    GIT_URL="https://gitlab.com/KevinJClark/ek47.git"
    REQUIREMENTS_FILE="requirements.txt"
    PIP_INSTALLS=()

    # Call the function
    _Install_Git_Python_Tool "${TOOL_NAME}" "${GIT_URL}" false "${REQUIREMENTS_FILE}" "${PIP_INSTALLS[@]}"
}
