#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : seclists.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

tool_categories["seclists"]="password-recovery"

function install_seclists() {
    _Git_Clone https://github.com/danielmiessler/SecLists.git
}

# Test function for statistically_likely_usernames
function test_seclists() {
    local TOOL_NAME="seclists"
    local TOOL_COMMAND="ls ${TOOLS_DIR}/SecLists"
    AppTest "${TOOL_NAME}" "${TOOL_COMMAND}"
    local status=$?

    # Return the status from AppTest
    return "${status}"
}
