#!/usr/bin/env bash

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
    _PipInstall "."
    _Popd
}

# Test function for webclientservicesscanner
function test_webclientservicesscanner() {
    local TOOL_NAME="webclientservicesscanner"
    local TOOL_COMMAND="webclientservicesscanner -h"
    AppTest "${TOOL_NAME}" "${TOOL_COMMAND}"
    local status=$?

    # Return the status from AppTest
    return "${status}"
}
