#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : netntlmtosilverticket.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

TOOL_CATEGORY_MAP["netntlmtosilverticket"]="post-exploitation"
APP_TESTS["netntlmtosilverticket"]="dementor.py -h"

function install_netntlmtosilverticket() {
    # Define the arguments
    TOOL_NAME="dementor.py"
    GIT_URL="https://github.com/NotMedic/NetNTLMtoSilverTicket.git"
    REQUIREMENTS_FILE=""
    PIP_INSTALLS=()

    # Call the function
    _Install_Git_Python_Tool "${TOOL_NAME}" "${GIT_URL}" true "${REQUIREMENTS_FILE}" "${PIP_INSTALLS[@]}"
}
