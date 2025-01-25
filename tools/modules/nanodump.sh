#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : nanodump.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:53:39
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:53:39  | Adam Compton | Initial creation.
# =============================================================================

TOOL_CATEGORY_MAP["nanodump"]="post-exploitation"
APP_TESTS["nanodump"]="ls ${TOOLS_DIR}/nanodump/dist"

function install_nanodump() {
    _Git_Clone https://github.com/fortra/nanodump.git
    _Pushd "${TOOLS_DIR}/nanodump"
    make -f Makefile.mingw
    _Popd
}
