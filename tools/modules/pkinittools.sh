#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : pkinittools.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

TOOL_CATEGORY_MAP["pkinittools"]="vulnerability-analysis"
APP_TESTS["pkinittools"]="gettgtpkinit.py -h"

function install_pkinittools() {
    # Define the arguments
    TOOL_NAME="gettgtpkinit.py"
    GIT_URL="https://github.com/dirkjanm/PKINITtools.git"
    REQUIREMENTS_FILE=""
    PIP_INSTALLS=("git+https://github.com/wbond/oscrypto.git" "minikerberos")

    # Call the function
    _Install_Git_Python_Tool "${TOOL_NAME}" "${GIT_URL}" false "${REQUIREMENTS_FILE}" "${PIP_INSTALLS[@]}"
}
