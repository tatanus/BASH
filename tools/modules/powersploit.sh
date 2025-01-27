#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : powersploit.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

TOOL_CATEGORY_MAP["powersploit"]="post-exploitation intelligence-gathering"
APP_TESTS["powersploit"]="ls ${TOOLS_DIR}/PowerSploit"

function install_powersploit() {
    _Git_Clone https://github.com/mattifestation/PowerSploit
}
