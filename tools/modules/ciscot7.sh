#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : ciscot7.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

TOOL_CATEGORY_MAP["ciscot7"]="password-recovery"
APP_TESTS["ciscot7"]="ciscot7.py --help"

function install_ciscot7() {
    # Define the arguments
    TOOL_NAME="ciscot7.py"
    GIT_URL="https://github.com/theevilbit/ciscot7.git"
    REQUIREMENTS_FILE=""
    PIP_INSTALLS=()

    # Call the function
    _Install_Git_Python_Tool "${TOOL_NAME}" "${GIT_URL}" false "${REQUIREMENTS_FILE}" "${PIP_INSTALLS[@]}"
}
