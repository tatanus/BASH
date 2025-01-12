#!/usr/bin/env bash
set -uo pipefail

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

    # Function to show a spinning wheel and elapsed time
    # Usage:
    #   show_spinner "$!"
    #   or
    #   show_spinner "long running command"
    # Function to show a spinner for a command or a running process
    function show_spinner() {
        local arg="$1"       # First argument, either a PID or a command
        local delay=0.1      # Delay between spinner updates
        local spin='|/-\'
        local start_time=$(date +%s) # Record the start time
        local pid             # PID to monitor
        local is_command=0    # Flag to determine if arg is a command

        # Determine if the argument is a PID or a command
        if [[ "$arg" =~ ^[0-9]+$ ]]; then
            pid="$arg" # Use the provided PID
        else
            is_command=1
            # Run the command in the same shell and get its PID
            eval "$arg &"
            pid=$!
        fi

        printf "Processing... (0s) "

        i=0
        while kill -0 "$pid" 2> /dev/null; do
            i=$(((i + 1) % 4))
            local current_time=$(date +%s)
            local elapsed=$((current_time - start_time))   # Calculate elapsed time

            # Update spinner and elapsed time
            printf "\rProcessing... ${spin:$i:1} (${elapsed}s) "
            sleep "$delay"
        done

        # Wait for the command (if applicable) and capture its exit code
        if [[ $is_command -eq 1 ]]; then
            wait "$pid"
        fi
        local exit_code=$?

        # Overwrite spinner with "Done!" or "Failed" and total elapsed time
        local total_time=$(($( date +%s) - start_time))
        if [[ $exit_code -eq 0 ]]; then
            printf "\rProcessing... Done! (Total time: ${total_time}s)\n"
        else
            printf "\rProcessing... Failed! (Total time: ${total_time}s)\n"
        fi

        return $exit_code
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
        local test_url="${1:-"http://google.com"}"  # Default test URL
        local timeout="${2:-5}"  # Timeout for connectivity tests

        info "Testing connectivity to ${test_url}..."

        # Test direct connectivity
        if curl -s --connect-timeout "${timeout}" "${test_url}" > /dev/null; then
            PROXY=""
            pass "Direct Internet access available. No proxy needed."
            return "${_PASS}"
        fi

        # Test connectivity via proxychains4
        if command -v proxychains4 > /dev/null 2>&1; then
            if proxychains4 -q curl -s --connect-timeout "${timeout}" "${test_url}" > /dev/null; then
                PROXY="proxychains4 -q "
                pass "Proxy required. Using proxychains4."
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
            CYGWIN* | MINGW* | MSYS* | Windows_NT)
                fail "Automatic installation for ${package_name} on Windows is not supported. Please install it manually."
                return "${_FAIL}"
                ;;
            *)
                fail "Unsupported operating system: ${OS_NAME}. Please install ${package_name} manually."
                return "${_FAIL}"
                ;;
        esac
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
