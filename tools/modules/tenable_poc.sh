#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : tenable_poc.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

tool_categories["spoonmap"]="exploitation"

function install_tenable_poc() {
    _Git_Clone https://github.com/tenable/poc.git "tenable_poc"
}

# Test function for tenable_poc
function test_tenable_poc() {
    local TOOL_NAME="tenable_poc"
    local TOOL_COMMAND="ls ${TOOLS_DIR}/tenable_poc"
    AppTest "${TOOL_NAME}" "${TOOL_COMMAND}"
    local status=$?

    # Return the status from AppTest
    return "${status}"
}
