#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : ntlmv1_multi.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

TOOL_CATEGORY_MAP["ntlmv1_multi"]="password-recovery post-exploitation"
APP_TESTS["ntlmv1_multi"]="ls ${TOOLS_DIR}/ntlmv1-multi"

function install_ntlmv1_multi() {
    _Git_Clone https://github.com/evilmog/ntlmv1-multi
}
