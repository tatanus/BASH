#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : sietpy3.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

TOOL_CATEGORY_MAP["sietpy3"]="exploitation post-exploitation"
APP_TESTS["sietpy3"]="SIETpy3.py -h"

function install_sietpy3() {
    _Git_Clone https://github.com/Sab0tag3d/SIETpy3.git

    _add_tool_function "SIETpy3.py" "SIETpy3/siet.py"
}
