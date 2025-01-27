#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : pywerview.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

TOOL_CATEGORY_MAP["pywerview"]="post-exploitation"
APP_TESTS["pywerview"]="pywerview.py -h"

function install_pywerview() {
    # Define the arguments
    TOOL_NAME="pywerview.py"
    GIT_URL="https://github.com/the-useless-one/pywerview"
    REQUIREMENTS_FILE=""
    PIP_INSTALLS=("bs4")
    #PIP_INSTALLS=(".")

    # Call the function
    _Install_Git_Python_Tool "${TOOL_NAME}" "${GIT_URL}" true "${REQUIREMENTS_FILE}" "${PIP_INSTALLS[@]}"
}
