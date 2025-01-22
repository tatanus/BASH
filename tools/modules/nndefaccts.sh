#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : nndefaccts.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

tool_categories["nndefaccts"]="vulnerability-analysis"

function install_nndefaccts() {
    _Git_Clone https://github.com/nnposter/nndefaccts.git
}

# Test function for nndefaccts
function test_nndefaccts() {
    local TOOL_NAME="nndefaccts"
    local TOOL_COMMAND="ls ${TOOLS_DIR}/nndefaccts"
    AppTest "${TOOL_NAME}" "${TOOL_COMMAND}"
    local status=$?

    # Return the status from AppTest
    return "${status}"
}
