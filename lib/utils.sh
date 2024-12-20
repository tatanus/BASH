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
            return $_PASS
        else
            return $_FAIL
        fi
    }

    # Pop directory from the stack
    function _Popd() {
        if popd > /dev/null 2>&1; then
            return $_PASS
        else
            return $_FAIL
        fi
    }



    # Function to remove a given path from $PATH
    function _Remove_From_PATH() {
        local path_to_remove="$1"

        # Check if the path_to_remove is provided
        if [ -z "$path_to_remove" ]; then
            echo "No path provided to remove from \$PATH."
            return $_FAIL
        fi

        # Remove the specified path from $PATH
        export PATH=$(echo "$PATH" | sed -e "s|$path_to_remove:||" \
                                         -e "s|:$path_to_remove||" \
                                         -e "s|$path_to_remove||")
    }

    # Check if a proxy is needed for internet access
    function _Check_Proxy_Needed() {
        local test_url="http://example.com"  # URL to test for internet access
        local timeout=5  # Timeout for curl command

        # Try to fetch the URL without a proxy
        if curl -s --connect-timeout $timeout "$test_url" > /dev/null; then
            PROXY=""  # No proxy needed
            success "No proxy needed."
            return $_PASS
        else
            # Check if proxychains4 is installed and $PROXY is set
            if ! command -v proxychains4 > /dev/null 2>&1; then
                fail "proxychains4 is not installed. Exiting."
                exit $_FAIL
            fi

            # Try to fetch the URL with proxychains4
            if proxychains4 -q curl -s --connect-timeout $timeout "$test_url" > /dev/null; then
                PROXY="proxychains4 -q "  # Proxy needed
                success "Proxy needed."
                return $_PASS
            else
                PROXY=""  # No proxy or other connectivity issues
                fail "No proxy exists or other connectivity issues. Exiting."
                exit $_FAIL
            fi
        fi
    }

    # Function to check if a variable is in a list
    function _In_List() {
        local select="$1"
        shift
        local command_list=("$@")

        for item in "${command_list[@]}"; do
            if [[ "$select" == "$item" ]]; then
                return $_PASS  # Item found
            fi
        done

        return $_FAIL  # Item not found
    }

    # Get the Ubuntu version
    function _Get_Ubuntu_Version() {
        local ubuntu_version

        # Extract the version from /etc/os-release or lsb_release
        if [ -f /etc/os-release ]; then
            ubuntu_version=$(grep -oP 'VERSION_ID="\K[^"]+' /etc/os-release)
        elif command -v lsb_release > /dev/null 2>&1; then
            ubuntu_version=$(lsb_release -rs)
        else
            fail "Unable to determine Ubuntu version."
            exit $_FAIL
        fi

        echo "$ubuntu_version"
    }

    # Get the macOS version
    function _Get_MacOS_Version() {
        local macos_version

        # Use the `sw_vers` command to fetch the macOS version
        if command -v sw_vers > /dev/null 2>&1; then
            macos_version=$(sw_vers -productVersion)
        else
            echo "[- FAIL  ] Unable to determine macOS version. 'sw_vers' command not found."
            exit $_FAIL
        fi

        echo "$macos_version"
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
                exit $_FAIL
            fi
        else
            echo "[- FAIL  ] This does not appear to be a Windows environment."
            exit $_FAIL
        fi

        echo "$windows_version"
    }

    _Install_Package() {
        local package="$1"
        if [[ "$(uname -s)" == "Darwin" ]]; then
            brew install "$package"
        else
            sudo apt-get install -y "$package"
        fi
    }

    source "$SCRIPT_DIR/lib/utils_apt.sh"
    source "$SCRIPT_DIR/lib/utils_py.sh"
    source "$SCRIPT_DIR/lib/utils_go.sh"
    source "$SCRIPT_DIR/lib/utils_ruby.sh"
    source "$SCRIPT_DIR/lib/utils_git.sh"
    source "$SCRIPT_DIR/lib/utils_curl.sh"
    source "$SCRIPT_DIR/lib/utils_fzf.sh"
    source "$SCRIPT_DIR/lib/utils_tools.sh"

fi