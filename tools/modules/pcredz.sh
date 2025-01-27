#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : pcredz.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

TOOL_CATEGORY_MAP["pcredz"]="intelligence-gathering"
APP_TESTS["pcredz"]="Pcredz -h"

function install_pcredz() {
    # Define the arguments
    TOOL_NAME="Pcredz"
    GIT_URL="https://github.com/lgandx/PCredz.git"
    REQUIREMENTS_FILE=""
    PIP_INSTALLS=("Cython" "python-libpcap")

    # Call the function
    _Install_Git_Python_Tool "${TOOL_NAME}" "${GIT_URL}" false "${REQUIREMENTS_FILE}" "${PIP_INSTALLS[@]}"
}
