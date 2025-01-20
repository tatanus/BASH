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

###############################################################################
# setup_msfdb_service
#==============================
# Creates and enables msfdb.service for systemd
# Ensures msfdb is started at system boot.
###############################################################################
function setup_msfdb_service() {
    local systemd_service_content="[Unit]
Description=Metasploit Database Service
After=postgresql.service
Wants=postgresql.service

[Service]
Type=oneshot
User=msftmpusr
ExecStart=/usr/bin/msfdb start
RemainAfterExit=true

[Install]
WantedBy=multi-user.target"

    info "Creating msfdb systemd service..."
    echo "${systemd_service_content}" | sudo tee /etc/systemd/system/msfdb.service > /dev/null || {
        fail "Failed to create msfdb.service file."
        return "${_FAIL}"
    }

    info "Enabling msfdb.service..."
    sudo systemctl daemon-reload
    if ! sudo systemctl enable msfdb; then
        fail "Failed to enable msfdb.service."
        return "${_FAIL}"
    fi

    info "Starting msfdb.service..."
    if ! sudo systemctl start msfdb; then
        fail "Failed to start msfdb.service."
        return "${_FAIL}"
    fi

    pass "msfdb.service successfully created and enabled."
    return "${_PASS}"
}

function install_metasploit() {
    if ${INSTALL_MEATASPLOIT}; then
        info "Starting Metasploit installation process..."

        # Ensure tools directory exists
        mkdir -p "${TOOLS_DIR}/metasploit" || {
            fail "Failed to create ${TOOLS_DIR}/metasploit."
            return "${_FAIL}"
        }
        _Pushd "${TOOLS_DIR}/metasploit" || {
            fail "Failed to change directory to ${TOOLS_DIR}/metasploit."
            return "${_FAIL}"
        }

        # Start and enable PostgreSQL with systemd
        info "Starting and enabling PostgreSQL..."
        if ! systemctl start postgresql; then
            fail "Failed to start PostgreSQL. Ensure it is installed."
            _Popd
            return "${_FAIL}"
        fi
        if ! systemctl enable postgresql; then
            fail "Failed to enable PostgreSQL to start on boot."
            _Popd
            return "${_FAIL}"
        fi

        # Create a temporary user to initialize msfdb
        info "Creating temporary user 'msftmpusr' for database initialization..."
        if ! sudo useradd -m -s /bin/bash -p "$(openssl passwd -1 'msftmpusrpwd')" msftmpusr; then
            fail "Failed to create temporary user."
            _Popd
            return "${_FAIL}"
        fi
        sudo usermod -aG sudo msftmpusr || {
            fail "Failed to add 'msftmpusr' to the sudo group."
            _Popd
            return "${_FAIL}"
        }

        # Download and run the Metasploit installation script
        info "Downloading and running Metasploit installation script..."
        if ! _Curl "https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb" "msfinstall"; then
            fail "Failed to download Metasploit installation script."
            _Popd
            return "${_FAIL}"
        fi
        chmod 755 msfinstall
        if ! ${PROXY} ./msfinstall; then
            fail "Failed to install Metasploit."
            rm -f msfinstall
            _Popd
            return "${_FAIL}"
        fi
        rm -f msfinstall

        # Initialize msfdb
        info "Initializing Metasploit database..."
        if ! sudo -u msftmpusr msfdb init; then
            fail "Failed to initialize msfdb."
            _Popd
            return "${_FAIL}"
        fi
        sudo -u msftmpusr msfdb status || {
            fail "msfdb status check failed."
            _Popd
            return "${_FAIL}"
        }

        # Configure database access for root
        info "Configuring database access for root user..."
        mkdir -p "${HOME}/.msf4"
        cp /home/msftmpusr/.msf4/database.yml "${HOME}/.msf4/" || {
            fail "Failed to copy database.yml to root's .msf4 directory."
            _Popd
            return "${_FAIL}"
        }
        chmod 600 "${HOME}/.msf4/database.yml"

        # Set up the msfdb systemd service
        info "[*] Setting up msfdb.service for systemd..."
        if ! setup_msfdb_service; then
            fail "Failed to configure msfdb.service."
            _Popd
            return "${_FAIL}"
        fi

        pass "Metasploit installation complete. msfdb is configured to start on boot."
        _Popd
        return "${_PASS}"
    else
        # Update existing Metasploit installation
        info "Updating Metasploit Framework..."
        if command -v msfupdate > /dev/null 2>&1; then
            if ! ${PROXY} msfupdate; then
                fail "Failed to update Metasploit Framework."
                return "${_FAIL}"
            fi
            pass "Metasploit Framework updated successfully."
            return "${_PASS}"
        else
            fail "msfupdate command not found. Is Metasploit installed?"
            return "${_FAIL}"
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
