#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : pretender.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:53:44
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:53:44  | Adam Compton | Initial creation.
# =============================================================================

TOOL_CATEGORY_MAP["pretender"]="exploitation"
APP_TESTS["pretender"]="pretender -h"

function install_pretender() {
    _Git_Clone https://github.com/RedTeamPentesting/pretender.git
    _Pushd "${TOOLS_DIR}"/pretender
    go build
    _Popd

    _add_tool_function "pretender" "pretender/pretender"
}
