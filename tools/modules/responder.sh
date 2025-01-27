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

TOOL_CATEGORY_MAP["responder"]="exploitation"
APP_TESTS["responder"]="Responder.py -h"

function install_responder() {
    _Git_Clone https://github.com/lgandx/Responder.git
    _Pushd "${TOOLS_DIR}"/Responder
    chmod +x Responder.py
    chmod +x DumpHash.py
    chmod +x Report.py
    _Popd

    _add_tool_function "Responder.py" "Responder/Responder.py"
}
