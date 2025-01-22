#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : ffuf.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

tool_categories["ffuf"]="intelligence-gathering exploitation"

function install_ffuf() {
    if _Git_Release "ffuf/ffuf" "linux_amd64" "${TOOLS_DIR}/ffuf"; then
        tar -C "${TOOLS_DIR}"/ffuf -xzvf "${TOOLS_DIR}"/ffuf/ffuf_*linux_amd64.tar.gz
        rm "${TOOLS_DIR}"/ffuf/ffuf_*linux_amd64.tar.gz

        _add_tool_function "ffuf" "ffuf/ffuf"
    fi
}

# Test function for ffuf
function test_ffuf() {
    local TOOL_NAME="ffuf"
    local TOOL_COMMAND="ffuf -h"
    AppTest "${TOOL_NAME}" "${TOOL_COMMAND}"
    local status=$?

    # Return the status from AppTest
    return "${status}"
}
