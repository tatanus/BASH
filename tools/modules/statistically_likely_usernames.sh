#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : statistically_likely_usernames.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

function install_statistically_likely_usernames() {
    _Git_Clone https://github.com/insidetrust/statistically-likely-usernames
}

# Test function for statistically_likely_usernames
function test_statistically_likely_usernames() {
    local TOOL_NAME="statistically_likely_usernames"
    local TOOL_COMMAND="ls ${TOOLS_DIR}/statistically-likely-usernames"
    AppTest "${TOOL_NAME}" "${TOOL_COMMAND}"
    local status=$?

    # Return the status from AppTest
    return "${status}"
}
