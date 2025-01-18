#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : petitpotam.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

function install_petitpotam() {
    # Define the arguments
    TOOL_NAME="PetitPotam.py"
    GIT_URL="https://github.com/topotam/PetitPotam.git"
    REQUIREMENTS_FILE=""
    PIP_INSTALLS=()

    # Call the function
    _Install_Git_Python_Tool "${TOOL_NAME}" "${GIT_URL}" true "${REQUIREMENTS_FILE}" "${PIP_INSTALLS[@]}"
}

# Test function for petitpotam
function test_petitpotam() {
    local TOOL_NAME="PetitPotam.py"
    local TOOL_COMMAND="PetitPotam.py -h"
    AppTest "${TOOL_NAME}" "${TOOL_COMMAND}" 2
    local status=$?

    # Return the status from AppTest
    return "${status}"
}
