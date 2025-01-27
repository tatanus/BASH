#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : statistically_likely_usernames.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

TOOL_CATEGORY_MAP["statistically_likely_usernames"]="intelligence-gathering"
APP_TESTS["statistically_likely_usernames"]="ls ${TOOLS_DIR}/statistically-likely-usernames"

function install_statistically_likely_usernames() {
    _Git_Clone https://github.com/insidetrust/statistically-likely-usernames
}
