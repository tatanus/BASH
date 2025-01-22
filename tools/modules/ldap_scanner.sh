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

tool_categories["ldap_scanner"]="intelligence-gathering"

function install_ldap_scanner() {
    # Define the arguments
    TOOL_NAME="ldap-scanner.py"
    GIT_URL="https://github.com/Rcarnus/ldap-scanner"
    REQUIREMENTS_FILE=""
    PIP_INSTALLS=()

    # Call the function
    _Install_Git_Python_Tool "${TOOL_NAME}" "${GIT_URL}" true "${REQUIREMENTS_FILE}" "${PIP_INSTALLS[@]}"
}

# Test function for ldap_scanner
function test_ldap_scanner() {
    local TOOL_NAME="ldap-scanner.py"
    local TOOL_COMMAND="ldap-scanner.py -h"
    AppTest "${TOOL_NAME}" "${TOOL_COMMAND}"
    local status=$?

    # Return the status from AppTest
    return "${status}"
}
