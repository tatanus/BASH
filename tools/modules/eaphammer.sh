#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : eaphammer.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

tool_categories["eaphammer"]="exploitation"

function install_eaphammer() {
    # Define the arguments
    TOOL_NAME="eaphammer"
    GIT_URL="https://github.com/s0lst1c3/eaphammer.git"
    REQUIREMENTS_FILE="pip.req"
    PIP_INSTALLS=()

    # Call the function
    _Install_Git_Python_Tool "${TOOL_NAME}" "${GIT_URL}" false "${REQUIREMENTS_FILE}" "${PIP_INSTALLS[@]}"

    # more setup
    # Determine DIRECTORY_NAME from GIT_URL
    local DIRECTORY_NAME="${GIT_URL}"

    # Remove .git suffix if it exists
    if [[ "${DIRECTORY_NAME}" == *.git ]]; then
        DIRECTORY_NAME=${DIRECTORY_NAME%.git}
    fi

    # remove everything  except after the last \
    DIRECTORY_NAME="${DIRECTORY_NAME##*/}"

    _Pushd "${TOOLS_DIR}/${DIRECTORY_NAME}"
    source ./venv/bin/activate
    sed -i 's/\._core\././' cert_wizard/cert_utils.py
    echo 'y' | ./kali-setup
    deactivate
    _Popd
}

# Test function for eaphammer
function test_eaphammer() {
    local TOOL_NAME="eaphammer"
    local TOOL_COMMAND="eaphammer -h"
    AppTest "${TOOL_NAME}" "${TOOL_COMMAND}" 1
    local status=$?

    # Return the status from AppTest
    return "${status}"
}
