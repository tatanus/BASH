#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : siet.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

tool_categories["siet"]="exploitation"

function install_siet() {
    _Git_Clone https://github.com/Sab0tag3d/SIET.git

    _add_tool_function "siet.py" "SIET/siet.py"
}

# Test function for siet
function test_siet() {
    local TOOL_NAME="siet.py"
    local TOOL_COMMAND="siet.py -h"
    AppTest "${TOOL_NAME}" "${TOOL_COMMAND}"
    local status=$?

    # Return the status from AppTest
    return "${status}"
}
