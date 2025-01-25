#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : seeyoucm_thief.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

TOOL_CATEGORY_MAP["seeyoucm_thief"]="exploitation"
APP_TESTS["seeyoucm_thief"]="thief.py -h"

function install_seeyoucm_thief() {
    # Define the arguments
    TOOL_NAME="thief.py"
    GIT_URL="https://github.com/trustedsec/SeeYouCM-Thief.git"
    REQUIREMENTS_FILE="requirements.txt"
    PIP_INSTALLS=()

    # Call the function
    _Install_Git_Python_Tool "${TOOL_NAME}" "${GIT_URL}" true "${REQUIREMENTS_FILE}" "${PIP_INSTALLS[@]}"
}
