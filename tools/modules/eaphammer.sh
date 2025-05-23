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

TOOL_CATEGORY_MAP["eaphammer"]="exploitation"
APP_TESTS["eaphammer"]="eaphammer -h"

function install_eaphammer() {
    # Define the arguments
    TOOL_NAME="eaphammer"
    GIT_URL="https://github.com/s0lst1c3/eaphammer.git"
    #REQUIREMENTS_FILE="pip.req"
    REQUIREMENTS_FILE="kali-dependencies.txt"
    PIP_INSTALLS=("service-identity")

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
    chmod +x ubuntu-unattended-setup
    ./ubuntu-unattended-setup
    deactivate
    _Popd
}
