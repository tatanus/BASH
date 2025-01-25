#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : webclientservicesscanner.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:53:52
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:53:52  | Adam Compton | Initial creation.
# =============================================================================

TOOL_CATEGORY_MAP["webclientservicesscanner"]="vulnerability-analysis"
APP_TESTS["webclientservicescanner"]="webclientservicescanner -h"

function install_webclientservicesscanner() {
    _Git_Clone https://github.com/Hackndo/WebclientServiceScanner.git
    _Pushd "${TOOLS_DIR}"/WebclientServiceScanner
    _Pip_Install "."
    _Popd
}
