#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : ridenum.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

TOOL_CATEGORY_MAP["ridenum"]="intelligence-gathering"
APP_TESTS["ridenum"]="ridenum.py -h"

function install_ridenum() {
    # Define the arguments
    TOOL_NAME="ridenum.py"
    GIT_URL="https://github.com/trustedsec/ridenum.git"
    REQUIREMENTS_FILE=""
    PIP_INSTALLS=()

    # Call the function
    _Install_Git_Python_Tool "${TOOL_NAME}" "${GIT_URL}" false "${REQUIREMENTS_FILE}" "${PIP_INSTALLS[@]}"
}
