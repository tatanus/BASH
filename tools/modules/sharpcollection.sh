#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : sharpcollection.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

tool_categories["sharpcollection"]="post-exploitation intelligence-gathering"

function install_sharpcollection() {
    _Git_Clone https://github.com/Flangvik/SharpCollection.git
}

# Test function for sharpcollection
function test_sharpcollection() {
    local TOOL_NAME="sharpcollection"
    local TOOL_COMMAND="ls ${TOOLS_DIR}/SharpCollection"
    AppTest "${TOOL_NAME}" "${TOOL_COMMAND}"
    local status=$?

    # Return the status from AppTest
    return "${status}"
}
