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

TOOL_CATEGORY_MAP["enum4linux"]="intelligence-gathering"
APP_TESTS["enum4linux"]="enum4linux.pl -h"

function install_enum4linux() {
    _Git_Clone https://github.com/CiscoCXSecurity/enum4linux.git
    _Curl "https://raw.githubusercontent.com/Wh1t3Fox/polenum/master/polenum.py" "/usr/local/bin/polenum"
    chmod +x /usr/local/bin/polenum

    _add_tool_function "enum4linux.pl" "enum4linux/enum4linux.pl"
    pass "enum4linux.pl installed and aliases added successfully."
}
