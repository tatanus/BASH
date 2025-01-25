#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : checkhashes.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

TOOL_CATEGORY_MAP["checkhashes"]="password-recovery post-exploitation"
APP_TESTS["check_hashes"]="check_hashes.py -h"

function install_checkhashes() {
    # Create directory for CheckHashes
    mkdir -p "${TOOLS_DIR}/CheckHashes"

    # Download check_hashes.py
    if ! _Curl "https://gist.githubusercontent.com/bandrel/3dd47c93cd430606865ec84d281913dc/raw/e9298bd831c214f2bea265137ec276fe3d7bbc28/check_hashes.py" "${TOOLS_DIR}/CheckHashes/check_hashes.py"; then
        fail "Failed to download check_hashes.py."
        return "${_FAIL}"
    fi

    # Add aliases for check_hashes
    _add_tool_function "check_hashes.py" "CheckHashes/check_hashes.py"
    pass "check_hashes installed and aliases added successfully."
}
