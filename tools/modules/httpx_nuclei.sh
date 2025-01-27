#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : httpx_nuclei.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

TOOL_CATEGORY_MAP["httpx"]="intelligence-gathering"
TOOL_CATEGORY_MAP["nuclei"]="intelligence-gathering"
APP_TESTS["httpx"]="httpx -h"
APP_TESTS["nuclei"]="nuclei -h"

function install_httpx_nuclei() {
    info "httpx and nuclei are installed via go"
    return
    # if _Git_Release "projectdiscovery/httpx" "linux_amd64" "${TOOLS_DIR}/httpx"; then
    #     unzip "${TOOLS_DIR}"/httpx/*.zip -d "${TOOLS_DIR}"/httpx/
    #     rm "${TOOLS_DIR}"/httpx/*.zip

    #     _Add_Alias "alias httpx='${TOOLS_DIR}/httpx/httpx'"
    # fi

    # if _Git_Release "projectdiscovery/nuclei" "linux_amd64" "${TOOLS_DIR}/nuclei"; then
    #     unzip "${TOOLS_DIR}"/nuclei/*.zip -d "${TOOLS_DIR}"/nuclei/
    #     rm "${TOOLS_DIR}"/nuclei/*.zip

    #     _Add_Alias "alias nuclei='${TOOLS_DIR}/nuclei/nuclei'"
    # fi

    # _Git_Clone https://github.com/projectdiscovery/nuclei-templates.git
}
