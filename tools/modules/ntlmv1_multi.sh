#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : ntlmv1_multi.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

tool_categories["ntlmv1_multi"]="password-recovery post-exploitation"

function install_ntlmv1_multi() {
    _Git_Clone https://github.com/evilmog/ntlmv1-multi
}

# Test function for ntlmv1_multi
function test_ntlmv1_multi() {
    local TOOL_NAME="ntlmv1_multi"
    local TOOL_COMMAND="ls ${TOOLS_DIR}/ntlmv1-multi"
    AppTest "${TOOL_NAME}" "${TOOL_COMMAND}"
    local status=$?

    # Return the status from AppTest
    return "${status}"
}
