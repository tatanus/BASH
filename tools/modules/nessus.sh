#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : nessus.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

function install_nessus() {
    # Check required environment variables
    check_env_var "INSTALL_NESSUS" || return "${_FAIL}"
    check_env_var "SETUP_NESSUS" || return "${_FAIL}"
    check_env_var "TOOLS_DIR" || return "${_FAIL}"
    check_env_var "PROXY" || return "${_FAIL}"
    check_env_var "NESSUS_LICENSE" || return "${_FAIL}"

    # Default values for NESSUS_USER and NESSUS_PASSWORD
    if ! check_env_var "NESSUS_USER"; then
        NESSUS_USER="pentest"
        warn "Setting default for NESSUS_USER: ${NESSUS_USER}"
    fi

    if ! check_env_var "NESSUS_PASSWORD"; then
        NESSUS_PASSWORD="S3cur!ty"
        warn "Setting default for NESSUS_PASSWORD: ${NESSUS_PASSWORD}"
    fi

    if ${INSTALL_NESSUS}; then
        mkdir -p "${TOOLS_DIR}"/nessus
        # Download Nessus
        LATEST_NESSUS=$(${PROXY} curl -s -k -L https://www.tenable.com/downloads/nessus?loginAttempted=true | sed 's/"id":/\n/g' | grep ubuntu | grep amd64 | grep meta_data | head -n1 | awk -F "," '{ print $1 }')
        _Curl "https://www.tenable.com/downloads/api/v1/public/pages/nessus/downloads/${LATEST_NESSUS}/download?i_agree_to_tenable_license_agreement=true" "${TOOLS_DIR}/nessus/nessus.deb"
        # Install Nessus
        dpkg -i "${TOOLS_DIR}"/nessus/nessus.deb
    fi
    if ${SETUP_NESSUS}; then
                # Add a new user (automated user addition)
        /opt/nessus/sbin/nessuscli adduser "${NESSUS_USER}" <<EOF
${NESSUS_PASSWORD}
${NESSUS_PASSWORD}
y

y
EOF
        # Make Nessus listen only on 127.0.0.1
        /opt/nessus/sbin/nessuscli fix --set listen_address=127.0.0.1
        # Register Nessus
        ${PROXY} /opt/nessus/sbin/nessuscli fetch --register-only  "${NESSUS_LICENSE}"
        # Install Nessus Plugins from the web
        ${PROXY} /opt/nessus/sbin/nessuscli update --plugins-only
        # Restart the daemon
        systemctl start nessusd.service
    fi
}

# Test function for nessus
function test_nessus() {
    local TOOL_NAME="nessus"
    local TOOL_COMMAND="/opt/nessus/bin/nasl -h"
    AppTest "${TOOL_NAME}" "${TOOL_COMMAND}"
    local status=$?

    # Return the status from AppTest
    return "${status}"
}
