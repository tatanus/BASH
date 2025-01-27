#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : autoproc.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

TOOL_CATEGORY_MAP["autoproc"]="post-exploitation"
APP_TESTS["autoProc"]="autoProc.py -h"

function install_autoproc() {
    # Create directory for autoProc
    mkdir -p "${TOOLS_DIR}/autoProc"

    # Download autoProc.py
    if ! _Curl "https://gist.githubusercontent.com/knavesec/0bf192d600ee15f214560ad6280df556/raw/36ff756346ebfc7f9721af8c18dff7d2aaf005ce/autoProc.py" "${TOOLS_DIR}/autoProc/autoProc.py"; then
        fail "Failed to download autoProc.py."
        return "${_FAIL}"
    fi

    # Add aliases for autoProc
    _add_tool_function "autoProc.py" "autoProc/autoProc.py"

    pass "autoProc installed and aliases added successfully."
}
