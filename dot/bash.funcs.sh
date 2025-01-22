#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : bash.funcs.sh
# DESCRIPTION : A collection of useful functions for Bash.
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-08 19:57:22
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-08 19:57:22  | Adam Compton | Initial creation.
# =============================================================================

# Guard to prevent multiple sourcing
if [[ -z "${BASH_FUNCS_SH_LOADED:-}" ]]; then
    declare -g BASH_FUNCS_SH_LOADED=true

    ###############################################################################
    # _get_os
    # Detects the current operating system.
    #
    # Returns one of:
    #   - macos
    #   - ubuntu
    #   - wsl        (if running under Windows Subsystem for Linux)
    #   - windows    (Cygwin/Mingw/MSYS-based or cmd.exe available)
    #   - linux      (generic Linux, not Ubuntu or WSL)
    #   - unknown    (none of the above)
    #
    # Usage:
    #   current_os="$(_get_os)"
    #   echo "OS: ${current_os}"
    ###############################################################################
    function _get_os() {
        local uname_output
        uname_output="$(uname -s)"

        # macOS check
        if [[ "${uname_output}" == "Darwin" ]]; then
            echo "macos"
            return
        fi

        # WSL detection: 'Microsoft' in /proc/version
        if grep -qi Microsoft /proc/version 2>/dev/null; then
            echo "wsl"
            return
        fi

        # Windows check (Cygwin/Mingw/MSYS)
        case "${uname_output}" in
            CYGWIN* | MINGW* | MSYS*)
                echo "windows"
                return
                ;;
            *)
                :
                ;;
        esac

        # Linux variants
        if [[ "${uname_output}" == "Linux" ]]; then
            # Check if /etc/os-release has "ubuntu"
            if [[ -f /etc/os-release ]] && grep -qi "ubuntu" /etc/os-release; then
                echo "ubuntu"
                return
            fi
            # Otherwise, generic Linux
            echo "linux"
            return
        fi

        # If no match, unknown
        echo "unknown"
    }

    ###############################################################################
    # _get_macos_version
    # Retrieves the macOS version string (e.g., "13.2.1") using `sw_vers -productVersion`.
    #
    # Outputs the version string on success. If `sw_vers` is not found or not on macOS,
    # prints an error message and exits with _FAIL.
    #
    # Usage:
    #   macos_ver="$(_get_macos_version)" || exit $?
    #   echo "macOS version: ${macos_ver}"
    ###############################################################################
    function _get_macos_version() {
        if [[ "$(_get_os)" != "macos" ]]; then
            echo "[- FAIL ] Not running on macOS." >&2
            return "${_FAIL}"
        fi

        if ! command -v sw_vers &>/dev/null; then
            echo "[- FAIL ] Unable to determine macOS version. 'sw_vers' not found." >&2
            return "${_FAIL}"
        fi

        local macos_version
        macos_version="$(sw_vers -productVersion 2>/dev/null  || true)"

        # Basic validation
        if [[ -z "${macos_version}" ]]; then
            echo "[- FAIL ] Could not retrieve macOS version." >&2
            return "${_FAIL}"
        fi

        echo "${macos_version}"
    }

    ###############################################################################
    # _get_ubuntu_version
    # Retrieves the Ubuntu version (e.g., "20.04") from /etc/os-release or lsb_release.
    #
    # Outputs the version string on success. If not on Ubuntu or cannot parse,
    # prints an error message and exits with _FAIL.
    #
    # Usage:
    #   ubuntu_ver="$(_get_ubuntu_version)" || exit $?
    #   echo "Ubuntu version: ${ubuntu_ver}"
    ###############################################################################
    function _get_ubuntu_version() {
        if [[ "$(_get_os)" != "ubuntu" ]]; then
            echo "[- FAIL ] Not running on Ubuntu." >&2
            return "${_FAIL}"
        fi

        local ubuntu_version=""
        if [[ -f /etc/os-release ]]; then
            # Extract the version from /etc/os-release
            # e.g. VERSION_ID="20.04"
            ubuntu_version="$(grep -oP 'VERSION_ID="\K[^"]+' /etc/os-release || true)"
        elif command -v lsb_release &>/dev/null; then
            ubuntu_version="$(lsb_release -rs 2>/dev/null  || true)"
        fi

        # Check if we got anything
        if [[ -z "${ubuntu_version}" ]]; then
            echo "[- FAIL ] Unable to determine Ubuntu version." >&2
            return "${_FAIL}"
        fi

        echo "${ubuntu_version}"
    }

    ###############################################################################
    # _get_windows_version
    # Retrieves the Windows version string (e.g., "10.0.19045") by calling `cmd.exe /c ver`
    # in Cygwin/Mingw/MSYS environments.
    #
    # Outputs the version string on success. If not on Windows or cannot parse,
    # prints an error message and exits with _FAIL.
    #
    # Usage:
    #   win_ver="$(_get_windows_version)" || exit $?
    #   echo "Windows version: ${win_ver}"
    ###############################################################################
    function _get_windows_version() {
        local current_os
        current_os="$(_get_os)"

        # We consider "windows" if it's CYGWIN, MINGW, or MSYS
        if [[ "${current_os}" != "windows" ]]; then
            echo "[- FAIL ] Not running on Windows (Cygwin/Mingw/MSYS)." >&2
            return "${_FAIL}"
        fi

        if ! command -v cmd.exe &>/dev/null; then
            echo "[- FAIL ] Unable to determine Windows version. 'cmd.exe' not found." >&2
            return "${_FAIL}"
        fi

        local ver_output
        ver_output="$(cmd.exe /c "ver" 2>/dev/null  || true)"
        # Typical output: "Microsoft Windows [Version 10.0.19045.3086]"
        local windows_version
        windows_version="$(echo "${ver_output}" | grep -oP '\[Version\s\K[^\]]+' || true)"

        if [[ -z "${windows_version}" ]]; then
            echo "[- FAIL ] Could not retrieve Windows version from 'cmd.exe /c ver'." >&2
            return "${_FAIL}"
        fi

        echo "${windows_version}"
    }

    ###############################################################################
    # _get_linux_version
    # Retrieves a generic Linux version from /etc/os-release if not on Ubuntu or WSL.
    # Returns an empty string if /etc/os-release doesn't exist or no version is found.
    #
    # Usage:
    #   linux_ver="$(_get_linux_version)"
    #   if [[ -n "${linux_ver}" ]]; then
    #       echo "Linux version: ${linux_ver}"
    #   else
    #       echo "Could not determine Linux version or not a recognized distro."
    #   fi
    ###############################################################################
    function _get_linux_version() {
        local current_os
        current_os="$(_get_os)"

        # We only attempt if it's "linux" from our detection
        if [[ "${current_os}" != "linux" ]]; then
            echo ""
            return 0
        fi

        if [[ ! -f /etc/os-release ]]; then
            # No /etc/os-release => no standard version info
            echo ""
            return 0
        fi

        local linux_version
        linux_version="$(grep -oP 'VERSION_ID="\K[^"]+' /etc/os-release || true)"

        echo "${linux_version}"
    }

    ###############################################################################
    # check_command
    # Checks for the availability of a specified command. If the command is not found,
    # outputs an error message with an OS-specific installation suggestion.
    #
    # Parameters:
    #   $1 - The name of the command to check (e.g., "ncat", "gsed").
    #
    # Returns:
    #   0 if the command exists.
    #   1 if the command does not exist.
    #
    # Usage:
    #   check_command "ncat" && alias nc="ncat"
    #   check_command "gsed" && alias sed="gsed"
    ###############################################################################
    function check_command() {
        local cmd="$1"

        # If the command is missing, we figure out how to install it
        if ! command -v "${cmd}" &>/dev/null; then
            local os
            os="$(_get_os)"

            # Decide on an install hint
            local install_hint
            case "${os}" in
                macos)
                    install_hint="brew install ${cmd}"
                    ;;
                ubuntu | wsl)
                    # Both Ubuntu and Debian-based WSL might use apt / apt-get
                    install_hint="sudo apt-get install ${cmd}"
                    ;;
                *)
                    # Fallback for unknown OS
                    install_hint="(please install ${cmd} manually)"
                    ;;
            esac

            echo "[${cmd}] is not installed. Some functionality may not work as expected."
            echo "Install [${cmd}] via [${install_hint}]."
            return 1
        fi
    }

    ###############################################################################
    # convert_ls_to_eza
    # Converts standard `ls` commands to `eza` commands with equivalent options.
    #
    # Parameters:
    #   Any arguments passed to `ls` (e.g., -la, --tree).
    #
    # Description:
    #   This function parses the provided `ls` arguments, translates them to `eza` equivalents,
    #   and executes the resulting `eza` command. It handles options like sorting and formatting.
    #
    # Usage:
    #   ls -la
    #   # Internally calls: convert_ls_to_eza -l -a
    ###############################################################################
    # Function to convert ls commands to eza commands
    function convert_ls_to_eza() {
        local cmd=("$@")                             # Capture all arguments as an array
        local eza_cmd=("eza" "--git" "-F" "-h" "-B") # Default eza command options

        # Separate options and arguments
        local options=()
        local arguments=()

        # Parse all arguments
        for arg in "${cmd[@]}"; do
            if [[ ${arg} == --* ]]; then
                # Long option (e.g., --tree, --group)
                options+=("${arg}")
            elif [[ ${arg} == -* ]]; then
                # Split combined short options into individual flags
                for ((i = 1; i < ${#arg}; i++)); do
                    options+=("-${arg:i:1}")
                done
            else
                # Non-option argument (e.g., file/directory)
                arguments+=("${arg}")
            fi
        done

        # Flags to track
        local has_t_flag=false
        local has_r_flag=false

        # Parse options to convert to eza equivalents
        for opt in "${options[@]}"; do
            case "${opt}" in
                -l) eza_cmd+=("-l" "--group") ;; # Long format with group info
                -t)
                    eza_cmd+=("--sort=modified")
                    has_t_flag=true
                    ;;                      # Sort by modification time
                -S) eza_cmd+=("--sort=size") ;; # Sort by file size
                -F) eza_cmd+=("--classify") ;; # Append indicator to entries
                -r) has_r_flag=true ;;      # Track -r flag
                *)
                    # Pass through unrecognized options (e.g., -Z, -U)
                    eza_cmd+=("${opt}")
                    ;;
            esac
        done

        # Handle -r and -t combinations
        if [[ "${has_t_flag}" == true && "${has_r_flag}" == true ]]; then
            # Drop -r if both -t and -r are present
            eza_cmd=("${eza_cmd[@]/--reverse/}") # Remove --reverse equivalent if already added
        elif [[ "${has_t_flag}" == true && "${has_r_flag}" == false ]]; then
            # Add -r if -t is present and -r is not
            eza_cmd+=("--reverse")
        elif [[ "${has_r_flag}" == true ]]; then
            # Add --reverse only if -r is used alone
            eza_cmd+=("--reverse")
        fi

        # Append non-option arguments to the command
        eza_cmd+=("${arguments[@]}")

        # Safely execute the final command
        "${eza_cmd[@]}"
    }

    ###############################################################################
    # _Pause
    # Pauses the execution of the script until the user presses any key.
    # Optionally clears the pause message from the terminal after the key press.
    #
    # Description:
    #   Displays a prompt message and waits for the user to press any key.
    #   After the key press, it clears the pause message from the terminal.
    #
    # Usage:
    #   _Pause
    ###############################################################################
    function _Pause() {
        echo
        echo "-----------------------------------"
        read -n 1 -s -r -p "Press any key to continue..."
        echo # Move to the next line after key press

        # Clear pause message from terminal
        if command -v tput &>/dev/null; then
            tput cuu 3
            tput el
            tput el
            tput el
        fi
    }

    ###############################################################################
    # get_session_name
    # Retrieves the current session names for TMUX or SCREEN environments.
    #
    # Returns:
    #   A comma-separated list of session names if in TMUX or SCREEN sessions.
    #   An empty string if not in any session.
    #
    # Usage:
    #   session_names="$(get_session_name)"
    #   echo "Current Sessions: ${session_names}"
    ###############################################################################
    function get_session_name() {
        local session_names=()

        # Check if we are in a TMUX session
        if [[ -n "${TMUX:-}" ]]; then
            local tmux_session
            tmux_session=$(tmux display-message -p '#S')
            session_names+=("TMUX:${tmux_session}")
        fi

        # Check if we are in a SCREEN session
        if [[ -n "${STY:-}" ]]; then
            local session_names
            screen_session=$(echo "${STY:-}" | awk -F '.' '{print $2}')
            session_names+=("SCREEN:${screen_session}")
        fi

        # Return session names, comma-separated if multiple
        if [[ ${#session_names[@]} -gt 0 ]]; then
            echo "${session_names[*]// /, }" # Replace spaces with commas
        fi
    }

    ###############################################################################
    # sort_first
    # Sorts Responder-style hashes in a file.
    #
    # Parameters:
    #   $@ - One or more file paths to sort.
    #
    # Description:
    #   Sorts the contents of the provided files uniquely and numerically.
    #
    # Usage:
    #   sort_first "hashes.txt"
    ###############################################################################
    function sort_first() {
        sort -u -V "$@" | sort -t: -k1,3 -u
    }

    ###############################################################################
    # strip_color
    # Removes ANSI escape sequences, control characters, and non-printable characters
    # from input strings or files.
    #
    # Parameters:
    #   $1 - A string or file path to process.
    #
    # Description:
    #   If the input is a file, it cleans the file's contents. Otherwise, it treats
    #   the input as a string and cleans it.
    #
    # Usage:
    #   strip_color "Colored Text"
    #   strip_color "/path/to/file.txt"
    ###############################################################################
    function strip_color() {
        # Check if an argument was provided
        if [[ -z "$1" ]]; then
            echo "Error: No input provided. Please pass a string or file."
            return 1
        fi

        # Corrected pattern to match ANSI escape codes and control characters
        local ansi_pattern=$'\x1B\\[[0-9;]*[mK]'  # ANSI color codes
        local control_pattern=$'[[:cntrl:]]'      # Control characters, including carriage return, etc.
        local nonprintable_pattern=$'[\x80-\xFF]' # Non-printable multibyte characters (like �)

        # Check if the input is a file
        if [[ -f "$1" ]]; then
            # Read file and clean non-printable characters and escape sequences
            LANG=C sed -E -e "s/${ansi_pattern}//g" \
                -e "s/${control_pattern}//g" \
                -e "s/${nonprintable_pattern}//g" "$1"
        else
            # Treat input as a string and clean non-printable characters and escape sequences
            echo -e "$1" | LANG=C sed -E -e "s/${ansi_pattern}//g" \
                -e "s/${control_pattern}//g" \
                -e "s/${nonprintable_pattern}//g"
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
        # shellcheck disable=SC1003
        local spin='|/-\\'
        local start_time
        start_time=$(date +%s) # Record the start time
        local pid             # PID to monitor
        local is_command=0    # Flag to determine if arg is a command

        # Determine if the argument is a PID or a command
        if [[ "${arg}" =~ ^[0-9]+$ ]]; then
            pid="${arg}" # Use the provided PID
        else
            is_command=1
            # Run the command in the same shell and get its PID
            eval "${arg} &"
            pid=$!
        fi

        printf "Processing... (0s) "

        i=0
        while kill -0 "${pid}" 2>/dev/null; do
            i=$(((i + 1) % 4))
            local current_time
            current_time=$(date +%s)
            local elapsed=$((current_time - start_time))   # Calculate elapsed time

            # Update spinner and elapsed time
            printf "\rProcessing... %s (%s seconds) " "${spin:${i}:1}" "${elapsed}"
            sleep "${delay}"
        done

        # Wait for the command (if applicable) and capture its exit code
        if [[ ${is_command} -eq 1 ]]; then
            wait "${pid}"
        fi
        local exit_code=$?

        # Overwrite spinner with "Done!" or "Failed" and total elapsed time
        local total_time=$(($( date +%s) - start_time))
        if [[ ${exit_code} -eq 0 ]]; then
            printf "\rProcessing... Done! (Total time: %s seconds)\n" "${total_time}"
        else
            printf "\rProcessing... Failed! (Total time: %s seconds)\n" "${total_time}"
        fi

        return "${exit_code}"
    }
fi
