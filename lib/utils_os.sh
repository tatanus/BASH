#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : utils_os.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-08 20:11:12
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-08 20:11:12  | Adam Compton | Initial creation.
# =============================================================================

# Guard to prevent multiple sourcing
if [[ -z "${UTILS_OS_SH_LOADED:-}" ]]; then
    declare -g UTILS_OS_SH_LOADED=true

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
                windows_version=$(cmd.exe /c "ver" 2> /dev/null | grep -oP '\[Version\s\K[^\]]+')
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

    # -----------------------------------------------------------------------------
    # ---------------------------------- OS VER CHECK -----------------------------
    # -----------------------------------------------------------------------------

    # Determine the operating system and version
    OS_NAME="$(uname -s)" # Get the OS name using `uname`
    OS_NAME="${OS_NAME:-unknown}"
    export OS_NAME

    # Initialize version variables for supported operating systems
    export UBUNTU_VER=""
    export MACOS_VER=""
    export WINDOWS_VER=""

    # Case statement to handle different operating systems
    case "${OS_NAME}" in
        Linux)
            # Check if the _Get_Ubuntu_Version function is available
            if ! command -v _Get_Ubuntu_Version &> /dev/null; then
                fail "Function _Get_Ubuntu_Version is not defined."
                exit "${_FAIL}"
            fi

            UBUNTU_VER=$(_Get_Ubuntu_Version) || {
                fail "Failed to determine Ubuntu version."
                exit "${_FAIL}"
            }

            export UBUNTU_VER
            pass "Detected Ubuntu version: ${UBUNTU_VER}"
            ;;
        Darwin)
            # Check if the _Get_MacOS_Version function is available
            if ! command -v _Get_MacOS_Version &> /dev/null; then
                fail "Function _Get_MacOS_Version is not defined."
                exit "${_FAIL}"
            fi

            MACOS_VER=$(_Get_MacOS_Version) || {
                fail "Failed to determine macOS version."
                exit "${_FAIL}"
            }

            export MACOS_VER
            pass "Detected macOS version: ${MACOS_VER}"
            ;;
        CYGWIN* | MINGW* | MSYS* | Windows_NT)
            # Handle Windows platforms
            # Check if the _Get_Windows_Version function is available
            if ! command -v _Get_Windows_Version &> /dev/null; then
                fail "Function _Get_Windows_Version is not defined."
                exit "${_FAIL}"
            fi

            WINDOWS_VER=$(_Get_Windows_Version) || {
                fail "Failed to determine Windows version."
                exit "${_FAIL}"
            }

            export WINDOWS_VER
            pass "Detected Windows version: ${WINDOWS_VER}"
            ;;
        *)
            # Handle unsupported operating systems
            fail "Unsupported operating system detected: ${OS_NAME}"
            exit "${_FAIL}"
            ;;
    esac
fi
