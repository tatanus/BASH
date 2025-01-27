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

TOOL_CATEGORY_MAP["sharpcollection"]="post-exploitation intelligence-gathering"
APP_TESTS["sharpcollection"]="ls ${TOOLS_DIR}/SharpCollection"

function install_sharpcollection() {
    _Git_Clone https://github.com/Flangvik/SharpCollection.git
}
