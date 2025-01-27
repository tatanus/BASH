#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : smbmap.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:53:50
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:53:50  | Adam Compton | Initial creation.
# =============================================================================

TOOL_CATEGORY_MAP["smbmap"]="intelligence-gathering"
APP_TESTS["smbmap"]="smbmap -h"

function install_smbmap() {
    _Git_Clone https://github.com/ShawnDEvans/smbmap
    _Pushd "${TOOLS_DIR}"/smbmap
    ${PYTHON} setup.py install
    _Popd
}
