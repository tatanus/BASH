#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : pywhisker.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2025-05-08 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2025-05-08 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

TOOL_CATEGORY_MAP["pywhisker"]="post-exploitation"
APP_TESTS["pywhisker"]="pywhisker.py -h"

function install_pywhisker() {
    # Define the arguments
    TOOL_NAME="pywhisker.py"
    GIT_URL="https://github.com/ShutdownRepo/pywhisker.git"
    REQUIREMENTS_FILE="requirements.txt"
    PIP_INSTALLS=()

    # Call the function
    _Install_Git_Python_Tool "${TOOL_NAME}" "${GIT_URL}" true "${REQUIREMENTS_FILE}" "${PIP_INSTALLS[@]}"
}
