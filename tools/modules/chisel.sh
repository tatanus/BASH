#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : chisel.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:53:25
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:53:25  | Adam Compton | Initial creation.
# =============================================================================

function install_chisel() {
    # Download and install chisel for Linux
    if _Git_Release "jpillora/chisel" "linux_amd64" "${TOOLS_DIR}/chisel"; then
        _Pushd "${TOOLS_DIR}/chisel"
        gunzip chisel_*_linux_amd64.gz
        chmod +x chisel_*_linux_amd64
        _Popd
    else
        fail "Failed to download chisel for Linux."
        return "${_FAIL}"
    fi

    # Download and install chisel for Windows
    if _Git_Release "jpillora/chisel" "windows_amd64" "${TOOLS_DIR}/chisel"; then
        _Pushd "${TOOLS_DIR}/chisel"
        gunzip chisel_*_windows_amd64.gz
        chmod +x chisel_*_windows_amd64
        _Popd
    else
        fail "Failed to download chisel for Windows."
        return "${_FAIL}"
    fi

    # Add alias for chisel
    _Add_Alias "alias chisel='${TOOLS_DIR}/chisel/chisel_*_linux_amd64'"
    pass "chisel installed and alias added successfully."
}

# Test function for chisel
function test_chisel() {
    local TOOL_NAME="chisel"
    local TOOL_COMMAND="chisel -h"
    AppTest "${TOOL_NAME}" "${TOOL_COMMAND}"
    local status=$?

    # Return the status from AppTest
    return "${status}"
}
