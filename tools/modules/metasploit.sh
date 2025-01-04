#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : metasploit.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:53:36
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:53:36  | Adam Compton | Initial creation.
# =============================================================================

function install_metasploit() {
    if ${INSTALL_MEATASPLOIT}; then
        mkdir "${TOOLS_DIR}"/metasploit
        _Pushd "${TOOLS_DIR}"/metasploit

        # start PostgreSQL
        sudo service postgresql start
        sudo update-rc.d postgresql enable

        # add a new user to init the msfdb
        sudo useradd -m -s /bin/bash -p "$(openssl passwd -1 'msftmpusrpwd')" msftmpusr
        sudo usermod -aG sudo msftmpusr

        # download and run the meatsploit install script
        _Curl "https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb" "msfinstall"
        chmod 755 msfinstall
        ${PROXY} ./msfinstall
        rm msfinstall

        # init the msfdb
        sudo -u msftmpusr msfdb init
        sudo -u msftmpusr msfdb status

        # make sure db connects for root user
        mkdir -p ~/.msf4
        cp /home/msftmpusr/.msf4/database.yml ~/.msf4/

        _Popd
    else
        # JUST UPDATE THE CURRENTLY INSTALLED VERSION
        if command -v msfupdate > /dev/null 2>&1; then
            ${PROXY} msfupdate
        fi
    fi
}

# Test function for metasploit
function test_metasploit() {
    local TOOL_NAME="metasploit"
    local TOOL_COMMAND="msfconsole -h"
    AppTest "${TOOL_NAME}" "${TOOL_COMMAND}"
    local status=$?

    # Return the status from AppTest
    return "${status}"
}
