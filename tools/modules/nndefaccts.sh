#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : nndefaccts.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

TOOL_CATEGORY_MAP["nndefaccts"]="vulnerability-analysis"
APP_TESTS["nndefaccts"]="ls ${TOOLS_DIR}/nndefaccts"

function install_nndefaccts() {
    _Git_Clone https://github.com/nnposter/nndefaccts.git
}
