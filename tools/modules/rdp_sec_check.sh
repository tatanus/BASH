#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : rdp_sec_check.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

function install_rdp_sec_check() {
    _Git_Clone https://github.com/CiscoCXSecurity/rdp-sec-check.git
    export PERL_MM_USE_DEFAULT=1
    ${PROXY} perl -MCPAN -e 'install Encoding::BER'

    _Add_Alias "alias rdp-sec-check.pl='${TOOLS_DIR}/rdp-sec-check/rdp-sec-check.pl'"
    _Add_Alias "alias rdp-sec-check='${TOOLS_DIR}/rdp-sec-check/rdp-sec-check.pl'"
}

# Test function for rdp_sec_check
function test_rdp_sec_check() {
    local TOOL_NAME="rdp_sec_check"
    local TOOL_COMMAND="rdp-sec-check -h"
    AppTest "${TOOL_NAME}" "${TOOL_COMMAND}"
    local status=$?

    # Return the status from AppTest
    return "${status}"
}
