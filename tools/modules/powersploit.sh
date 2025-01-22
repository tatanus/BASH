#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : powersploit.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

tool_categories["powersploit"]="post-exploitation intelligence-gathering"

function install_powersploit() {
    _Git_Clone https://github.com/mattifestation/PowerSploit
}

# Test function for powersploit
function test_powersploit() {
    local TOOL_NAME="powersploit"
    local TOOL_COMMAND="ls ${TOOLS_DIR}/PowerSploit"
    AppTest "${TOOL_NAME}" "${TOOL_COMMAND}"
    local status=$?

    # Return the status from AppTest
    return "${status}"
}
