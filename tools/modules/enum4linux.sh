#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : enum4linux.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

tool_categories["enum4linux"]="intelligence-gathering"

function install_enum4linux() {
    _Git_Clone https://github.com/CiscoCXSecurity/enum4linux.git
    _Curl "https://raw.githubusercontent.com/Wh1t3Fox/polenum/master/polenum.py" "/usr/local/bin/polenum"
    chmod +x /usr/local/bin/polenum

    _add_tool_function "enum4linux.pl" "enum4linux/enum4linux.pl"
    pass "enum4linux.pl installed and aliases added successfully."
}

# Test function for enum4linux
function test_enum4linux() {
    local TOOL_NAME="enum4linux.pl"
    local TOOL_COMMAND="enum4linux.pl -h"
    AppTest "${TOOL_NAME}" "${TOOL_COMMAND}"
    local status=$?

    # Return the status from AppTest
    return "${status}"
}
