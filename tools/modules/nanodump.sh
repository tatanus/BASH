#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : nanodump.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:53:39
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:53:39  | Adam Compton | Initial creation.
# =============================================================================

tool_categories["nanodump"]="post-exploitation"

function install_nanodump() {
    _Git_Clone https://github.com/fortra/nanodump.git
    _Pushd "${TOOLS_DIR}/nanodump"
    make -f Makefile.mingw
    _Popd
}

# Test function for nanodump
function test_nanodump() {
    local TOOL_NAME="nanodump"
    local TOOL_COMMAND="ls ${TOOLS_DIR}/nanodump/dist"
    AppTest "${TOOL_NAME}" "${TOOL_COMMAND}"
    local status=$?

    # Return the status from AppTest
    return "${status}"
}
