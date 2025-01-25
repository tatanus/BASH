#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : dotnet.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:53:34
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:53:34  | Adam Compton | Initial creation.
# =============================================================================

TOOL_CATEGORY_MAP["dotnet"]="post-exploitation exploitation"
APP_TESTS["dotnet"]="dotnet -h"

function install_dotnet() {
    # Get Ubuntu version
    ubuntu_version=$(lsb_release -rs)

    _Pushd "${TOOLS_DIR}"

    # Install dotnet SDK based on Ubuntu version
    if [[ "${ubuntu_version}" == "20.04" ]]; then
        _Curl "https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb" "packages-microsoft-prod.deb"
        sudo dpkg -i packages-microsoft-prod.deb
        rm packages-microsoft-prod.deb
    elif [[ "${ubuntu_version}" == "22.04" ]]; then
        _Apt_Install "dotnet-sdk-8.0"
        ${PROXY} apt install -y dotnet-sdk-7.0
    elif [[ "${ubuntu_version}" == "23.10" ]]; then
        _Apt_Install "dotnet-sdk-8.0"
    elif [[ "${ubuntu_version}" == "24.04" ]]; then
        _Apt_Install "dotnet-sdk-8.0"
    else
        _Apt_Install "dotnet-sdk-8.0"
    fi

    _Popd
}
