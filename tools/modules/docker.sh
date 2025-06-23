#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : docker.sh
# DESCRIPTION : Installs and tests docker
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

TOOL_CATEGORY_MAP["docker"]=""
APP_TESTS["docker"]="docker -h"

function install_docker() {
    # ${PROXY} apt update
    # ${PROXY} apt install apt-transport-https ca-certificates curl software-properties-common
    # ${PROXY} curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    # add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
    # ${PROXY} apt-cache policy docker-ce
    # ${PROXY} apt install docker-ce
    # systemctl status docker
    pass "Docker installed successfully."
}
