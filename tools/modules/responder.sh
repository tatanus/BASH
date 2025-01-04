#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : responder.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:53:46
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:53:46  | Adam Compton | Initial creation.
# =============================================================================

function install_responder() {
    _Git_Clone https://github.com/lgandx/Responder.git
    _Pushd "${TOOLS_DIR}"/Responder
    chmod +x Responder.py
    chmod +x DumpHash.py
    chmod +x Report.py
    _Popd

    _Add_Alias "function Responder { (cd ${TOOLS_DIR}/Responder && ${PYTHON} ${TOOLS_DIR}/Responder/Responder.py \"\$@\") }"
}

# Test function for responder
function test_responder() {
    local TOOL_NAME="responder"
    local TOOL_COMMAND="Responder -h"
    AppTest "${TOOL_NAME}" "${TOOL_COMMAND}"
    local status=$?

    # Return the status from AppTest
    return "${status}"
}
