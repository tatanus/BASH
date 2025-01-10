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

function install_webclientservicesscanner() {
    _Git_Clone https://github.com/Hackndo/WebclientServiceScanner.git
    _Pushd "${TOOLS_DIR}"/WebclientServiceScanner
    _Pip_Install "."
    _Popd
}

# Test function for webclientservicesscanner
function test_webclientservicesscanner() {
    local TOOL_NAME="webclientservicescanner"
    local TOOL_COMMAND="webclientservicescanner -h"
    AppTest "${TOOL_NAME}" "${TOOL_COMMAND}"
    local status=$?

    # Return the status from AppTest
    return "${status}"
}
