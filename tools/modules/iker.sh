#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : iker.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-19 10:52:12
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-19 10:52:12  | Adam Compton | Initial creation.
# =============================================================================

TOOL_CATEGORY_MAP["iker"]="vulnerability-analysis"
APP_TESTS["iker"]="iker.py -h"

function install_iker() {
    # Define the arguments
    TOOL_NAME="iker.py"
    GIT_URL="https://github.com/Zamanry/iker.git"
    REQUIREMENTS_FILE=""
    PIP_INSTALLS=()

    _Apt_Install ike-scan

    # Call the function
    _Install_Git_Python_Tool "${TOOL_NAME}" "${GIT_URL}" false "${REQUIREMENTS_FILE}" "${PIP_INSTALLS[@]}"
}
