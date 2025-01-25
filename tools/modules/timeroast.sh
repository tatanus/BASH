#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : timeroast.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

TOOL_CATEGORY_MAP["timeroast"]="password-recovery post-exploitation"
APP_TESTS["timeroast"]="timeroast.py -h"

function install_timeroast() {
    # Define the arguments
    TOOL_NAME="timeroast.py"
    GIT_URL="https://github.com/SecuraBV/Timeroast.git"
    REQUIREMENTS_FILE=""
    PIP_INSTALLS=()

    # Call the function
    _Install_Git_Python_Tool "${TOOL_NAME}" "${GIT_URL}" false "${REQUIREMENTS_FILE}" "${PIP_INSTALLS[@]}"
}
