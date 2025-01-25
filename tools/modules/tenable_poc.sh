#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : tenable_poc.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

TOOL_CATEGORY_MAP["tenable_poc"]="exploitation"
APP_TESTS["tenable_poc"]="ls ${TOOLS_DIR}/tenable_poc"

function install_tenable_poc() {
    _Git_Clone https://github.com/tenable/poc.git "tenable_poc"
}
