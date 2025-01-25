#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : crackmapexec.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:53:29
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:53:29  | Adam Compton | Initial creation.
# =============================================================================

TOOL_CATEGORY_MAP["crackmapexec"]="post-exploitation"
APP_TESTS["crackmapexec"]="cme -h"

function install_crackmapexec() {
    _Git_Clone https://github.com/byt3bl33d3r/CrackMapExec.git
    _Pushd "${TOOLS_DIR}"/CrackMapExec
    _Pipx_Install .
    _Popd
}
