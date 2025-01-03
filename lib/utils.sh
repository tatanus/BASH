#!/usr/bin/env bash

# =============================================================================
# NAME        : utils.sh
# DESCRIPTION : 
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-15 21:16:38
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-15 21:16:38  | Adam Compton | Initial creation.
# =============================================================================

# Guard to prevent multiple sourcing
if [[ -z "${UTILS_SH_LOADED:-}" ]]; then
    declare -g UTILS_SH_LOADED=true

    # pass/fail/true/fall variables
    _PASS=0
    _FAIL=1

    export DEBIAN_FRONTEND=noninteractive

    # -----------------------------------------------------------------------------
    # ---------------------------------- GENERAL FUNCTIONS ------------------------
    # -----------------------------------------------------------------------------

    # Push to a directory, creating it if it doesn't exist
    function _Pushd() {
        mkdir -p "$1"
        if pushd "$1" > /dev/null 2>&1; then
            return "${_PASS}"
        else
            return "${_FAIL}"
        fi
    }

    # Pop directory from the stack
    function _Popd() {
        if popd > /dev/null 2>&1; then
            return "${_PASS}"
        else
            return "${_FAIL}"
        fi
    }

    # Function to remove a given path from $PATH
    function _Remove_From_PATH() {
        local path_to_remove="$1"

        # Check if the path_to_remove is provided
        if [[ -z "${path_to_remove}" ]]; then
            echo "No path provided to remove from \$PATH."
            return "${_FAIL}"
        fi

        # Remove the specified path from $PATH
        PATH_TEMP=$(echo "${PATH}" | sed -e "s|${path_to_remove}:||" \
            -e "s|:${path_to_remove}||" \
            -e "s|${path_to_remove}||")
        export PATH="${PATH_TEMP}"
    }

    # Check and set proxy if required
    function _Check_Proxy_Needed() {
        local test_url=${1:-"http://google.com"}  # Default test URL
        local timeout=${2:-5}  # Timeout for connectivity tests

        info "Testing connectivity to ${test_url}..."

        # Test direct connectivity
        if curl -s --connect-timeout "${timeout}" "${test_url}" >/dev/null; then
            PROXY=""
            success "Direct Internet access available. No proxy needed."
            return "${_PASS}"
        fi

        # Test connectivity via proxychains4
        if command -v proxychains4 >/dev/null 2>&1; then
            if proxychains4 -q curl -s --connect-timeout "${timeout}" "${test_url}" >/dev/null; then
                PROXY="proxychains4 -q "
                success "Proxy required. Using proxychains4."
                return "${_PASS}"
            else
                fail "Proxychains4 is available but cannot connect to ${test_url}."
            fi
        else
            fail "Direct access failed and proxychains4 is not installed."
        fi

        PROXY=""
        fail "No Internet access available."
        return "${_FAIL}"
    }

    # Function to check if a variable is in a list
    function _In_List() {
        local select="$1"
        shift
        local command_list=("$@")

        for item in "${command_list[@]}"; do
            if [[ "${select}" == "${item}" ]]; then
                return "${_PASS}"  # Item found
            fi
        done

        return "${_FAIL}"  # Item not found
    }

    # Get the Ubuntu version
    function _Get_Ubuntu_Version() {
        local ubuntu_version

        # Extract the version from /etc/os-release or lsb_release
        if [[ -f /etc/os-release ]]; then
            ubuntu_version=$(grep -oP 'VERSION_ID="\K[^"]+' /etc/os-release)
        elif command -v lsb_release > /dev/null 2>&1; then
            ubuntu_version=$(lsb_release -rs)
        else
            fail "Unable to determine Ubuntu version."
            exit "${_FAIL}"
        fi

        echo "${ubuntu_version}"
    }

    # Get the macOS version
    function _Get_MacOS_Version() {
        local macos_version

        # Use the `sw_vers` command to fetch the macOS version
        if command -v sw_vers > /dev/null 2>&1; then
            macos_version=$(sw_vers -productVersion)
        else
            echo "[- FAIL  ] Unable to determine macOS version. 'sw_vers' command not found."
            exit "${_FAIL}"
        fi

        echo "${macos_version}"
    }

    # Get the Windows version
    function _Get_Windows_Version() {
        local windows_version

        # Check if running on Windows
        if [[ "$(uname -s)" =~ (CYGWIN|MINGW|MSYS|Linux) ]]; then
            # Use `cmd.exe` to fetch the Windows version
            if command -v cmd.exe > /dev/null 2>&1; then
                windows_version=$(cmd.exe /c "ver" 2>/dev/null | grep -oP '\[Version\s\K[^\]]+')
            else
                echo "[- FAIL  ] Unable to determine Windows version. 'cmd.exe' not found."
                exit "${_FAIL}"
            fi
        else
            echo "[- FAIL  ] This does not appear to be a Windows environment."
            exit "${_FAIL}"
        fi

        echo "${windows_version}"
    }

    # Generalized package installation function
    function _install_package() {
        local package_name="$1"

        if [[ -z "${package_name}" ]]; then
            fail "Package name is required for installation."
            return "${_FAIL}"
        fi

        info "Installing ${package_name} for ${OS_NAME}..."

        case "${OS_NAME}" in
            Linux)
                if [[ -n "${UBUNTU_VER}" ]]; then
                    _Apt_Install "${package_name}"
                    return $?
                else
                    fail "Unsupported Linux distribution. Please install ${package_name} manually."
                    return "${_FAIL}"
                fi
                ;;
            Darwin)
                _brew_install "${package_name}"
                return $?
                ;;
            CYGWIN*|MINGW*|MSYS*|Windows_NT)
                fail "Automatic installation for ${package_name} on Windows is not supported. Please install it manually."
                return "${_FAIL}"
                ;;
            *)
                fail "Unsupported operating system: ${OS_NAME}. Please install ${package_name} manually."
                return "${_FAIL}"
                ;;
        esac
    }

    # Dynamically source all utils_*.sh files from the lib directory
    for utils_file in "${SCRIPT_DIR}"/lib/utils_*.sh; do
        if [[ -f "${utils_file}" ]]; then
            source "${utils_file}"
            info "Sourced: ${utils_file}"
        else
            fail "No matching files to source in ${SCRIPT_DIR}/lib/"
            exit 1
        fi
    done

fi
