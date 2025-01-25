#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : siet.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

TOOL_CATEGORY_MAP["siet"]="exploitation"
APP_TESTS["siet"]="siet.py -h"

function install_siet() {
    _Git_Clone https://github.com/Sab0tag3d/SIET.git

    _add_tool_function "siet.py" "SIET/siet.py"
}
