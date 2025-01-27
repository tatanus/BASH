#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : spoonmap.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

TOOL_CATEGORY_MAP["spoonmap"]="intelligence-gathering"
APP_TESTS["spoonmap"]="ls ${TOOLS_DIR}/spoonmap/spoonmap.py"

function install_spoonmap() {
    _Git_Clone https://github.com/trustedsec/spoonmap.git

    _add_tool_function "spoonmap.py" "spoonmap/spoonmap.py"
}
