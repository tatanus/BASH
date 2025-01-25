#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : seclists.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

TOOL_CATEGORY_MAP["seclists"]="password-recovery"
APP_TESTS["seclists"]="ls ${TOOLS_DIR}/SecLists"

function install_seclists() {
    _Git_Clone https://github.com/danielmiessler/SecLists.git
}
