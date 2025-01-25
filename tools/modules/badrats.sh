#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : badrats.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

TOOL_CATEGORY_MAP["badrats"]="post-exploitation"
APP_TESTS["badrats"]="true"

function install_badrats() {
    # Define the arguments
    TOOL_NAME="badrat_server"
    GIT_URL="https://gitlab.com/KevinJClark/badrats.git"
    REQUIREMENTS_FILE="requirements.txt"
    PIP_INSTALLS=()

    # Call the function
    _Install_Git_Python_Tool "${TOOL_NAME}" "${GIT_URL}" false "${REQUIREMENTS_FILE}" "${PIP_INSTALLS[@]}"
}
