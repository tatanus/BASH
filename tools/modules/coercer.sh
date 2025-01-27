#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : coercer.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

TOOL_CATEGORY_MAP["coercer"]="exploitation post-exploitation"
APP_TESTS["coercer"]="Coercer.py -h"

function install_coercer() {
    # Define the arguments
    TOOL_NAME="Coercer.py"
    GIT_URL="https://github.com/p0dalirius/Coercer.git"
    REQUIREMENTS_FILE="requirements.txt"
    PIP_INSTALLS=("six" "pycryptodomex" "pyasn1" "markupsafe")

    # Call the function
    _Install_Git_Python_Tool "${TOOL_NAME}" "${GIT_URL}" true "${REQUIREMENTS_FILE}" "${PIP_INSTALLS[@]}"
}
