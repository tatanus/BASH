#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : unicorn.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2025-01-01 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2025-01-01 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

TOOL_CATEGORY_MAP["unicorn"]="post-exploitation"
APP_TESTS["unicorn"]="unicorn.py -h"

function install_unicorn() {
    # Define the arguments
    TOOL_NAME="unicorn.py"
    GIT_URL="https://github.com/trustedsec/unicorn.git"
    REQUIREMENTS_FILE=""
    PIP_INSTALLS=()

    # Call the function
    _Install_Git_Python_Tool "${TOOL_NAME}" "${GIT_URL}" false "${REQUIREMENTS_FILE}" "${PIP_INSTALLS[@]}"
}
