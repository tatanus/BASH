#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : jexboss.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

TOOL_CATEGORY_MAP["jexboss"]="exploitation"
APP_TESTS["jexboss"]="jexboss.py -h"

function install_jexboss() {
    # Define the arguments
    TOOL_NAME="jexboss.py"
    GIT_URL="https://github.com/joaomatosf/jexboss.git"
    REQUIREMENTS_FILE="requires.txt"
    PIP_INSTALLS=()

    # Call the function
    _Install_Git_Python_Tool "${TOOL_NAME}" "${GIT_URL}" false "${REQUIREMENTS_FILE}" "${PIP_INSTALLS[@]}"
}
