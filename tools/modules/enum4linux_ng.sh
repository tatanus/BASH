#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : enum4linux_ng.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

TOOL_CATEGORY_MAP["enum4linux_ng"]="intelligence-gathering"
APP_TESTS["enum4linux_ng"]="enum4linux-ng.py -h"

function install_enum4linux_ng() {
    # Define the arguments
    TOOL_NAME="enum4linux-ng.py"
    GIT_URL="https://github.com/cddmp/enum4linux-ng"
    REQUIREMENTS_FILE="requirements.txt"
    PIP_INSTALLS=(".")

    # Call the function
    _Install_Git_Python_Tool "${TOOL_NAME}" "${GIT_URL}" false "${REQUIREMENTS_FILE}" "${PIP_INSTALLS[@]}"
}
