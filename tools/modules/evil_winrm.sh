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

TOOL_CATEGORY_MAP["evil-winrm"]="post-exploitation"
APP_TESTS["evil_winrm"]="evil-winrm -h"

function install_evil_winrm() {
    info "evil-winrm is installed via ruby"
    return
    # ${PROXY} gem install nori -v 2.6.0 #temp fix until Ruby is upgraded
    # ${PROXY} gem install evil-winrm
}
