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

TOOL_CATEGORY_MAP["rdp_sec_check"]="vulnerability-analysis"
APP_TESTS["rdp_sec_check"]="rdp-sec-check.pl -h"

function install_rdp_sec_check() {
    _Git_Clone https://github.com/CiscoCXSecurity/rdp-sec-check.git
    export PERL_MM_USE_DEFAULT=1
    ${PROXY} perl -MCPAN -e 'install Encoding::BER'

    _add_tool_function "rdp-sec-check.pl" "rdp-sec-check/rdp-sec-check.pl"
}
