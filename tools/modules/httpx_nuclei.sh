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

# Test function for httpx
function test_httpx() {
    local TOOL_NAME="httpx"
    local TOOL_COMMAND="httpx -h"
    AppTest "${TOOL_NAME}" "${TOOL_COMMAND}"
    local status=$?

    # Return the status from AppTest
    return "${status}"
}

# Test function for nuclei
function test_nuclei() {
    local TOOL_NAME="nuclei"
    local TOOL_COMMAND="nuclei -h"
    AppTest "${TOOL_NAME}" "${TOOL_COMMAND}"
    local status=$?

    # Return the status from AppTest
    return "${status}"
}

# Test function for httpx_nuclei
function test_httpx_nuclei() {
    test_httpx
    test_nuclei
}
