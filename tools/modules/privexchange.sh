#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : privexchange.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

TOOL_CATEGORY_MAP["privexchange"]="post-exploitation"
APP_TESTS["privexchange"]="privexchange.py -h"

function install_privexchange() {
    # Define the arguments
    TOOL_NAME="privexchange.py"
    GIT_URL="https://github.com/dirkjanm/PrivExchange"
    REQUIREMENTS_FILE="requirements.txt"
    PIP_INSTALLS=()

    # Call the function
    _Install_Git_Python_Tool "${TOOL_NAME}" "${GIT_URL}" false "${REQUIREMENTS_FILE}" "${PIP_INSTALLS[@]}"
}
