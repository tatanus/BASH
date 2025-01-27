#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : spoofy.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-19 10:38:56
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-19 10:38:56  | Adam Compton | Initial creation.
# =============================================================================

TOOL_CATEGORY_MAP["spoofy"]="intelligence-gathering"
APP_TESTS["spoofy"]="spoofy.py -h"

function install_spoofy() {
    # Define the arguments
    TOOL_NAME="spoofy.py"
    GIT_URL="https://github.com/MattKeeley/Spoofy.git"
    REQUIREMENTS_FILE="requirements.txt"
    PIP_INSTALLS=()

    # Call the function
    _Install_Git_Python_Tool "${TOOL_NAME}" "${GIT_URL}" false "${REQUIREMENTS_FILE}" "${PIP_INSTALLS[@]}"
}
