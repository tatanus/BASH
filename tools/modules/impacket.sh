#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : impacket.sh
# DESCRIPTION : Installs and tests Impacket
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

tool_categories["impacket"]="exploitation post-exploitation"

function install_impacket() {
    # Define the Git repository URL for Impacket
    local GIT_URL="https://github.com/fortra/impacket.git"
    local PACKAGE_NAME="impacket"

    # Check if the Impacket directory already exists
    if check_dir_exists "${TOOLS_DIR}/${PACKAGE_NAME}"; then
        warn "Directory already exists: ${TOOLS_DIR}/${PACKAGE_NAME}"
        return "${_PASS}"
    fi

    # Clone the Git repository
    if ! _Git_Clone "${GIT_URL}"; then
        fail "Failed to clone repository from ${GIT_URL}."
        return "${_FAIL}"
    else
        pass "Successfully cloned ${PACKAGE_NAME} repository."
    fi

    # Navigate to the cloned repository
    _Pushd "${TOOLS_DIR}/${PACKAGE_NAME}" || {
        fail "Failed to change to directory ${TOOLS_DIR}/${PACKAGE_NAME}" >&2
        return "${_FAIL}"
    }

    # Install the package using pipx
    if ! _Pipx_Install "."; then
        fail "Failed to install package in ${TOOLS_DIR}/${PACKAGE_NAME}."
        _Popd
        return "${_FAIL}"
    else
        pass "Successfully installed ${PACKAGE_NAME}."
    fi

    # Return to the previous directory
    _Popd

    # Indicate successful installation
    pass "${PACKAGE_NAME} installed successfully."
    return "${_PASS}"
}

# Test function for impacket
function test_impacket() {
    local TOOL_NAME="secretsdump.py"
    local TOOL_COMMAND="secretsdump.py -h"
    AppTest "${TOOL_NAME}" "${TOOL_COMMAND}"
    local status=$?

    # Return the status from AppTest
    return "${status}"
}
