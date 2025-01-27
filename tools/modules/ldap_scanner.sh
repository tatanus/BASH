#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : ldap_scanner.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

TOOL_CATEGORY_MAP["ldap_scanner"]="intelligence-gathering"
APP_TESTS["ldap_scanner"]="ldap-scanner.py -h"

function install_ldap_scanner() {
    # Define the arguments
    TOOL_NAME="ldap-scanner.py"
    GIT_URL="https://github.com/Rcarnus/ldap-scanner"
    REQUIREMENTS_FILE=""
    PIP_INSTALLS=()

    # Call the function
    _Install_Git_Python_Tool "${TOOL_NAME}" "${GIT_URL}" true "${REQUIREMENTS_FILE}" "${PIP_INSTALLS[@]}"
}
