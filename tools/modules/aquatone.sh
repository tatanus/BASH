#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : aquatone.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

function install_aquatone() {
    # Install Chrome
    if ! _Curl "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb" /tmp/google-chrome-stable_current_amd64.deb; then
        fail "Failed to download Google Chrome."
        return "${_FAIL}"
    fi

    if ! gdebi --non-interactive /tmp/google-chrome-stable_current_amd64.deb; then
        fail "Failed to install Google Chrome."
        rm /tmp/google-chrome-stable_current_amd64.deb
        return "${_FAIL}"
    fi

    rm /tmp/google-chrome-stable_current_amd64.deb

    # Create directory for Aquatone
    mkdir -p "${TOOLS_DIR}/aquatone"

    # Download and install Aquatone
    if _Git_Release "michenriksen/aquatone" "linux_amd64" "${TOOLS_DIR}/aquatone"; then
        if ! unzip "${TOOLS_DIR}/aquatone/aquatone_linux_amd64_*.zip" -d "${TOOLS_DIR}/aquatone/"; then
            fail "Failed to unzip Aquatone package."
            return "${_FAIL}"
        fi
        rm "${TOOLS_DIR}/aquatone/aquatone_linux_amd64_*.zip"
    else
        fail "Failed to download Aquatone release."
        return "${_FAIL}"
    fi

    # Add alias for Aquatone
    _Add_Alias "alias aquatone='${TOOLS_DIR}/aquatone/aquatone'"
    success "Aquatone installed and alias added successfully."
}

# Test function for aquatone
function test_aquatone() {
    local TOOL_NAME="aquatone"
    local TOOL_COMMAND="aquatone -h"
    AppTest "${TOOL_NAME}" "${TOOL_COMMAND}"
    local status=$?

    # Return the status from AppTest
    return "${status}"
}
