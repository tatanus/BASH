#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : bloodhound.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

TOOL_CATEGORY_MAP["bloodhound"]="post-exploitation intelligence-gathering"
APP_TESTS["bloodhound"]="bloodhound.py -h"

function install_bloodhound() {
    # Define the arguments
    TOOL_NAME="bloodhound.py"
    GIT_URL="https://github.com/fox-it/BloodHound.py"
    REQUIREMENTS_FILE=""
    PIP_INSTALLS=(".", "git+https://github.com/ly4k/ldap3")

    # Call the function
    _Install_Git_Python_Tool "${TOOL_NAME}" "${GIT_URL}" false "${REQUIREMENTS_FILE}" "${PIP_INSTALLS[@]}"
}
