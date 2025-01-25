#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : netexec.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:53:41
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:53:41  | Adam Compton | Initial creation.
# =============================================================================

TOOL_CATEGORY_MAP["netexec"]="exploitation"
APP_TESTS["netexec"]="nxc -h"

function install_netexec() {
    info "netexec is installed via pipx"
    return
    # _Git_Clone https://github.com/Pennyw0rth/NetExec.git
    # _Pushd "${TOOLS_DIR}"/NetExec
    # _Pipx_Install .
    # _Popd
}
