#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : ldaprelayscan.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

TOOL_CATEGORY_MAP["ldaprelayscan"]="intelligence-gathering exploitation"
APP_TESTS["ldaprelayscan"]="LdapRelayScan.py -h"

function install_ldaprelayscan() {
    # Define the arguments
    TOOL_NAME="LdapRelayScan.py"
    GIT_URL="https://github.com/zyn3rgy/LdapRelayScan"
    REQUIREMENTS_FILE="requirements_exact.txt"
    PIP_INSTALLS=()

    # Call the function
    _Install_Git_Python_Tool "${TOOL_NAME}" "${GIT_URL}" false "${REQUIREMENTS_FILE}" "${PIP_INSTALLS[@]}"
}
