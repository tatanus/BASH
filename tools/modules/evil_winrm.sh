#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : evil_winrm.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

tool_categories["evil-winrm"]="post-exploitation"

function install_evil_winrm() {
    info "evil-winrm is installed via ruby"
    return
    # ${PROXY} gem install nori -v 2.6.0 #temp fix until Ruby is upgraded
    # ${PROXY} gem install evil-winrm
}

# Test function for evil_winrm
function test_evil_winrm() {
    local TOOL_NAME="evil_winrm"
    local TOOL_COMMAND="evil-winrm -h"
    AppTest "${TOOL_NAME}" "${TOOL_COMMAND}"
    local status=$?

    # Return the status from AppTest
    return "${status}"
}
