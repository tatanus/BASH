#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : dfscoerce.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

TOOL_CATEGORY_MAP["dfscoerce"]="exploitation post-exploitation"
APP_TESTS["dfscoerce"]="dfscoerce.py -h"

function install_dfscoerce() {
    # Define the arguments
    TOOL_NAME="dfscoerce.py"
    GIT_URL="https://github.com/Wh04m1001/DFSCoerce.git"
    REQUIREMENTS_FILE=""
    PIP_INSTALLS=()

    # Call the function
    _Install_Git_Python_Tool "${TOOL_NAME}" "${GIT_URL}" true "${REQUIREMENTS_FILE}" "${PIP_INSTALLS[@]}"
}
