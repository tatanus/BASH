#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : kerbrute.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

TOOL_CATEGORY_MAP["kerbrute"]="exploitation post-exploitation password-recovery"
APP_TESTS["kerbrute"]="kerbrute -h"

function install_kerbrute() {
    if _Git_Release "ropnop/kerbrute" "linux_amd64" "${TOOLS_DIR}/kerbrute"; then
        chmod +x "${TOOLS_DIR}"/kerbrute/kerbrute_linux_amd64

        _add_tool_function "kerbrute" "kerbrute/kerbrute_linux_amd64"
    fi
}
