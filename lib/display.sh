#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : display.sh
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
if [[ -z "${DISPLAY_SH_LOADED:-}" ]]; then
    declare -g DISPLAY_SH_LOADED=true

    # -----------------------------------------------------------------------------
    # --------------------------------- DISPLAY -----------------------------------
    # -----------------------------------------------------------------------------

    # Define colors using tput for compatibility across systems
    light_green=$(tput setaf 2)
    light_blue=$(tput setaf 6)
    blue=$(tput setaf 4)
    light_red=$(tput setaf 1)
    yellow=$(tput setaf 3)
    orange=$(tput setaf 214 2> /dev/null || tput setaf 3) # Fallback to yellow if 214 isn't supported
    white=$(tput setaf 7)
    reset=$(tput sgr0)

    # Log and display messages with color and type
    # $1: Message type (info, success, warning, fail, debug)
    # $2: Message content
    # $3: Context (e.g., menu name, optional)
    function log_message() {
        local type="$1"
        local message="$2"
        local context="${3:-General}"

        # Determine prefix and color
        local prefix color
        case "${type}" in
            info)
                prefix="[* INFO  ]"
                color="${blue}"
                ;;
            success)
                prefix="[+ PASS  ]"
                color="${light_green}"
                ;;
            warning)
                prefix="[! WARN  ]"
                color="${yellow}"
                ;;
            fail)
                prefix="[- FAIL  ]"
                color="${light_red}"
                ;;
            debug)
                prefix="[# DEBUG ]"
                color="${orange}"
                ;;
            *)
                echo -e "${light_red}[- FAIL  ] Invalid log type: ${type}${reset}" >&2
                return "${_FAIL}"
                ;;
        esac

        # Construct log entry
        local timestamp
        timestamp=$(date +"[%Y-%m-%d %H:%M:%S]")
        local log_entry="${timestamp} [${context}] ${message}"

        # Display to screen with color
        if [[ "${NO_DISPLAY}" != "true" ]]; then
            echo -e "${color}${prefix} ${message}${reset}"

            # Automatically call debug if DEBUG is true, but avoid infinite loop
            if [[ "${DEBUG:-false}" == true && "${type}" != "debug" ]]; then
                # Capture the caller stack info from log_message
                local caller_info
                caller_info=$(caller 1) # Get the caller of log_message
                debug "${message}" "${context}" "${caller_info}"
            fi
        fi

        # Write to log file
        echo "${log_entry}" >> "${LOG_FILE}"

    }

    # Wrapper functions for each log type
    function info()    { log_message "info" "${1:-}" "${2:-}"; }
    function success() { log_message "success" "${1:-}" "${2:-}"; }
    function pass()    { log_message "success" "${1:-}" "${2:-}"; }
    function warning() { log_message "warning" "${1:-}" "${2:-}"; }
    function warn()    { log_message "warning" "${1:-}" "${2:-}"; }
    function fail()    { log_message "fail" "${1:-}" "${2:-}"; }

    # Debug function with caller information
    # $1: Debug message
    # $2: Context (optional)
    # $3: Caller information (optional)
    function debug() {
        local message="$1"
        local context="${2:-General}"
        local caller_info="${3:-$(caller 0)}"

        # Parse caller information
        local line_number
        local function_name
        local file_name
        read -r line_number function_name file_name <<< "$(echo "${caller_info}" | awk '{print $1, $2, $3}')"

        # Include detailed debug information
        local debug_message="CALLER: ${file_name}:${line_number} (${function_name}) - ${message}"
        log_message "debug" "${debug_message}" "${context}"
    }

    function _Pause() {
        echo
        echo "-----------------------------------"
        read -n 1 -s -r -p "Press any key to continue..."
        echo  # Move to the next line after key press

        # Use ANSI escape codes to move the cursor up and clear lines
        tput cuu 3   # Move the cursor up 3 lines
        tput el      # Clear the current line
        tput el      # Clear the next line
        tput el      # Clear the third line
    }
fi
