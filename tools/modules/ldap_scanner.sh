#!/usr/bin/env bash

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

function install_ldap_scanner() {
    # Define the arguments
    TOOL_NAME="ldap-scanner"
    GIT_URL="https://github.com/Rcarnus/ldap-scanner"
    REQUIREMENTS_FILE=""
    PIP_INSTALLS=()

    # Call the function
    _Install_Git_Python_Tool "${TOOL_NAME}" "${GIT_URL}" true "${REQUIREMENTS_FILE}" "${PIP_INSTALLS[@]}"
}

# Test function for ldap_scanner
function test_ldap_scanner() {
    local TOOL_NAME="ldap_scanner"
    local TOOL_COMMAND="ldap-scanner -h"
    AppTest "${TOOL_NAME}" "${TOOL_COMMAND}"
    local status=$?

    # Return the status from AppTest
    return "${status}"
}
