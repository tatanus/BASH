#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : donpapi.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:53:31
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:53:31  | Adam Compton | Initial creation.
# =============================================================================

TOOL_CATEGORY_MAP["donpapi"]="exploitation post-exploitation"
APP_TESTS["donpapi"]="donpapi -h"

function install_donpapi() {
    _Git_Clone https://github.com/login-securite/DonPAPI.git
    _Pushd "${TOOLS_DIR}"/DonPAPI
    _Pipx_Install .
    _Popd
}
