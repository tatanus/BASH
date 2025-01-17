#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : sietpy3.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

function install_sietpy3() {
    _Git_Clone https://github.com/Sab0tag3d/SIETpy3.git

    _add_tool_function "SIETpy3.py" "SIETpy3/siet.py"
}

# Test function for sietpy3
function test_sietpy3() {
    local TOOL_NAME="sietpy3"
    local TOOL_COMMAND="sietpy3 -h"
    AppTest "${TOOL_NAME}" "${TOOL_COMMAND}"
    local status=$?

    # Return the status from AppTest
    return "${status}"
}
