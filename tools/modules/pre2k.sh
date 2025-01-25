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

TOOL_CATEGORY_MAP["pre2k"]="password-recovery post-exploitation"
APP_TESTS["pre2k"]="pre2k.py -h"

function install_pre2k() {
    # Define the arguments
    TOOL_NAME="pre2k.py"
    GIT_URL="https://github.com/garrettfoster13/pre2k-TS.git"
    REQUIREMENTS_FILE="requirements.txt"
    PIP_INSTALLS=("rich" "pycryptodome")

    # Call the function
    _Install_Git_Python_Tool "${TOOL_NAME}" "${GIT_URL}" false "${REQUIREMENTS_FILE}" "${PIP_INSTALLS[@]}"
}
