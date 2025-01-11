#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : enum4linux_ng.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

function install_enum4linux_ng() {
    # Define the arguments
    TOOL_NAME="enum4linux-ng"
    GIT_URL="https://github.com/cddmp/enum4linux-ng"
    REQUIREMENTS_FILE="requirements.txt"
    PIP_INSTALLS=(".")

    # Call the function
    _Install_Git_Python_Tool "${TOOL_NAME}" "${GIT_URL}" false "${REQUIREMENTS_FILE}" "${PIP_INSTALLS[@]}"
}

# Test function for enum4linux_ng
function test_enum4linux_ng() {
    local TOOL_NAME="enum4linux_ng"
    local TOOL_COMMAND="enum4linux-ng -h"
    AppTest "${TOOL_NAME}" "${TOOL_COMMAND}" 2
    local status=$?

    # Return the status from AppTest
    return "${status}"
}
