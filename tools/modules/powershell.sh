#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : powershell.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:53:34
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:53:34  | Adam Compton | Initial creation.
# =============================================================================

TOOL_CATEGORY_MAP["powershell"]="post-exploitation exploitation"
APP_TESTS["powershell"]="pwsh -v"

function install_powershell() {
    GITHUB_RELEASE_URL="https://github.com/PowerShell/PowerShell/releases/latest"

    # Fetch the latest release page URL (handles redirection)
    latest_release_url=$(${PROXY} curl -sIL -o /dev/null -w "%{url_effective}" "${GITHUB_RELEASE_URL}")

    # Extract the latest version tag from the URL
    latest_version=$(basename "${latest_release_url}")

    # Construct the API URL to fetch release assets
    release_api_url="https://api.github.com/repos/PowerShell/PowerShell/releases/tags/${latest_version}"

    # Fetch JSON data for the latest release and extract the deb_amd64.deb file URL
    latest_deb_url=$(${PROXY} curl -s "${release_api_url}" | jq -r '.assets[] | select(.name | endswith("deb_amd64.deb")) | .browser_download_url' | head -n 1)

    # Check if a URL was found
    if [[ -z "${latest_deb_url}" || "${latest_deb_url}" == "null" ]]; then
        fail "Could not find a downloadable .deb file." >&2
        return "${_FAIL}"
    fi

    _Pushd "${TOOLS_DIR}"

    _Curl "${latest_deb_url}" "powershell.deb_amd64.deb"
    sudo dpkg -i powershell.deb_amd64.deb
    rm packages-microsoft-prod.deb
    _Apt_Install_Missing_Dependencies

    _Popd
}
