#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : logger.sh
# DESCRIPTION : A modular and instance-based logging utility for Bash scripts.
#               - Provides configurable log levels (debug, info, warn, etc.)
#               - Supports logging to both console and file.
#               - Enables creation of multiple logger instances.
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-08 20:11:12
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-08 20:11:12  | Adam Compton | Initial creation.
# =============================================================================

# Guard to prevent multiple sourcing
if [[ -z "${LOGGER_SH_LOADED:-}" ]]; then
    declare -g LOGGER_SH_LOADED=true

    # =============================================================================
    # Define colors for screen output
    # =============================================================================

    # Check if `tput` is available; otherwise, use ANSI escape codes as fallback
    if command -v tput &> /dev/null; then
        light_green=$(tput setaf 2)
        light_blue=$(tput setaf 6)
        blue=$(tput setaf 4)
        light_red=$(tput setaf 1)
        yellow=$(tput setaf 3)
        orange=$(tput setaf 214 2> /dev/null || tput setaf 3) # Fallback to yellow if 214 isn't supported
        white=$(tput setaf 7)
        reset=$(tput sgr0)
    else
        light_green="\033[0;32m"
        light_blue="\033[1;36m"
        blue="\033[0;34m"
        light_red="\033[0;31m"
        yellow="\033[0;33m"
        orange="\033[1;33m"  # Fallback to yellow
        white="\033[0;37m"
        reset="\033[0m"
    fi

    # =============================================================================
    # Valid logging levels
    # =============================================================================
    # Define log levels and their priorities
    declare -gA log_level_priorities
    log_level_priorities[debug]=1
    log_level_priorities[info]=2
    log_level_priorities[warn]=3
    log_level_priorities[pass]=4
    log_level_priorities[fail]=5

    # =============================================================================
    # Validates an instance name to ensure it's a valid Bash variable name.
    # =============================================================================
    function _validate_instance_name() {
        local name=$1
        if [[ ! "${name}" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
            printf "Error: Invalid instance name '%s'. Must start with a letter or underscore and contain only alphanumeric characters and underscores.\n" "${name}" >&2
            return 1
        fi
    }

    # =============================================================================
    # Validates if a given log level is valid
    # =============================================================================
    function _validate_log_level() {
        local -r level="${1:-}"

        # Check if level is empty
        if [[ -z "${level}" ]]; then
            printf "Error: Log level is empty. Valid levels are: %s.\n" \
                "${!log_level_priorities[*]}" >&2
            return 1
        fi

        # Check if level exists in log_level_priorities
        if [[ -z "${log_level_priorities[${level}]:-}" ]]; then
            printf "Error: Invalid log level '%s'. Valid levels are: %s.\n" \
                "${level}" "${!log_level_priorities[*]}" >&2
            return 1
        fi
    }

    # =============================================================================
    # Initializes a new logger instance
    # =============================================================================
    function Logger_Init() {
        local -r instance_name="${1:-default}"
        local -r log_file="${2:-${HOME}/${instance_name}.log}" # Default log file
        local -r log_level="${3:-info}"
        local -r log_to_screen="${4:-true}"
        local -r log_to_file="${5:-true}"

        # Validate instance name
        _validate_instance_name "${instance_name}" || return 1

        # Validate log level
        _validate_log_level "${log_level}" || return 1

        # Ensure log file directory exists
        if [[ -z "${log_file}" || "${log_file}" == */* && ! -d "$(dirname "${log_file}")" ]]; then
            printf "Error: Log file directory does not exist or is not writable: %s\n" "$(dirname "${log_file}")" >&2
            return 1
        fi

        # Validate boolean values for log_to_screen and log_to_file
        if [[ "${log_to_screen}" != "true" && "${log_to_screen}" != "false" ]]; then
            printf "Error: log_to_screen must be 'true' or 'false'.\n" >&2
            return 1
        fi

        if [[ "${log_to_file}" != "true" && "${log_to_file}" != "false" ]]; then
            printf "Error: log_to_file must be 'true' or 'false'.\n" >&2
            return 1
        fi

        # Create an empty associative array for the instance
        declare -gA "${instance_name}_props"

        # Check if the array is declared
        declare -p "${instance_name}_props" 2> /dev/null || {
            echo "Failed to declare ${instance_name}_props" >&2
            return 1
        }

        # Set properties using _Logger_set_property
        _Logger_set_property "${instance_name}" "log_file" "${log_file}"
        _Logger_set_property "${instance_name}" "log_level" "${log_level}"
        _Logger_set_property "${instance_name}" "log_to_screen" "${log_to_screen}"
        _Logger_set_property "${instance_name}" "log_to_file" "${log_to_file}"

        # Dynamically define methods for this instance
        eval "
            ${instance_name}.info() { Logger_log '${instance_name}' 'info' \"\${1:-}\"; }
            ${instance_name}.warn() { Logger_log '${instance_name}' 'warn' \"\${1:-}\"; }
            ${instance_name}.pass() { Logger_log '${instance_name}' 'pass' \"\${1:-}\"; }
            ${instance_name}.fail() { Logger_log '${instance_name}' 'fail' \"\${1:-}\"; }
            ${instance_name}.debug() { Logger_log '${instance_name}' 'debug' \"\${1:-}\"; }
            ${instance_name}.set_log_to_screen() { _Logger_set_property '${instance_name}' 'log_to_screen' \"\${1:-}\"; }
            ${instance_name}.get_log_to_screen() { _Logger_get_property '${instance_name}' 'log_to_screen'; }
            ${instance_name}.set_log_to_file() { _Logger_set_property '${instance_name}' 'log_to_file' \"\${1:-}\"; }
            ${instance_name}.get_log_to_file() { _Logger_get_property '${instance_name}' 'log_to_file'; }
            ${instance_name}.set_log_level() { _Logger_set_property '${instance_name}' 'log_level' \"\${1:-}\"; }
            ${instance_name}.get_log_level() { _Logger_get_property '${instance_name}' 'log_level'; }
        "
    }

    # =============================================================================
    # Generates a timestamp for log entries
    # =============================================================================
    function _Logger_timestamp() {
        date +"[%Y-%m-%d %H:%M:%S]"
    }

    # =============================================================================
    # Logs a message for the given instance and log level.
    # =============================================================================
    function Logger_log() {
        local -r instance_name="${1:-default}"
        local -r level="${2:="debug"}"
        local -r message="${3:-}" # Allow blank messages
        local -r caller_info="${4:-$(caller 1)}" # Caller information for debug messages

        # Validate the log level
        _validate_log_level "${level}" || return 1
            # Validate the log level
        if ! _validate_log_level "${level}"; then
            # Print error and propagate failure
            printf "Error: Invalid log level '%s'\n" "${level}"
            return 1
        fi

        # Validate that the instance exists
        if ! declare -p "${instance_name}_props" &> /dev/null; then
            printf "Error: Logger instance '%s' does not exist.\n" "${instance_name}" >&2
            return 1
        fi

        # Retrieve properties
        local log_file log_level log_to_screen log_to_file
        log_file=$(_Logger_get_property "${instance_name}" "log_file")
        log_level=$(_Logger_get_property "${instance_name}" "log_level")
        log_to_screen=$(_Logger_get_property "${instance_name}" "log_to_screen")
        log_to_file=$(_Logger_get_property "${instance_name}" "log_to_file")

        # Get priorities for the current log level and the message log level
        local current_priority priority
        current_priority="${log_level_priorities[${log_level}]}"
        priority="${log_level_priorities[${level}]}"

        # Ensure priorities are valid
        if [[ -z "${current_priority}" || -z "${priority}" ]]; then
            printf "Error: Invalid log level priority.\n" >&2
            return 1
        fi

        # Skip logging if the message level is below the instance's configured level
        if [[ "${priority}" -lt "${current_priority}" ]]; then
            return 0
        fi

        # Parse caller information for debug messages
        local debug_info=""
        if [[ "${level}" == "debug" ]]; then
            # Parse the `caller` information for line number, function, and file name
            local line_number function_name file_name
            read -r line_number function_name file_name <<< "$(echo "${caller_info}" | awk '{print $1, $2, $3}')"
            debug_info="CALLER: ${file_name}:${line_number} (${function_name})"
        fi

        # Define log levels and their prefixes
        local timestamp prefix formatted_message
        timestamp=$(date +"[%Y-%m-%d %H:%M:%S]")
        case "${level}" in
            debug) prefix="[# DEBUG ]" ;;
            info)  prefix="[* INFO  ]" ;;
            warn)  prefix="[! WARN  ]" ;;
            pass)  prefix="[+ PASS  ]" ;;
            fail)  prefix="[- FAIL  ]" ;;
            *)     prefix="[UNKNOWN ]" ;;  # Fallback for unexpected log levels
        esac

        # Format the log message, including debug info if applicable
        if [[ -n "${debug_info}" ]]; then
            formatted_message="${debug_info} - ${message}"
        else
            formatted_message="${message}"
        fi

        local error=false

        # Log to file if enabled
        if [[ "${log_to_file}" == "true" ]]; then
            if ! printf "%s\n" "${timestamp} ${prefix} ${formatted_message}" >> "${log_file}"; then
                printf "Error: Failed to write to log file: %s\n" "${log_file}" >&2
                error=true
            fi
        fi

        # Log to screen if enabled
        if [[ "${log_to_screen}" == "true" ]]; then
            local color
            case "${level}" in
                debug) color="${orange}" ;;
                info)  color="${blue}" ;;
                warn)  color="${yellow}" ;;
                pass)  color="${light_green}" ;;
                fail)  color="${light_red}" ;;
                *)     color="${white}" ;;
            esac
            printf "%s %b%s%b %s\n" "${timestamp}" "${color}" "${prefix}" "${reset}" "${formatted_message}"
        fi

        # Return status based on the error state
        if [[ "${error}" == "true" ]]; then
            return 1
        else
            return 0
        fi
    }

    # =============================================================================
    # Set a property for a logger instance
    # =============================================================================
    function _Logger_set_property() {
        local instance_name=$1
        local property=$2
        local value=$3

        # Ensure the instance's associative array is declared
        if ! declare -p "${instance_name}_props" &> /dev/null; then
            echo "Error: Logger instance '${instance_name}' is not declared." >&2
            return 1
        fi

        # Validate property names and values
        case "${property}" in
            log_level)
                _validate_log_level "${value}" || return 1
                ;;
            log_to_screen | log_to_file)
                if [[ "${value}" != "true" && "${value}" != "false" ]]; then
                    printf "Error: %s must be 'true' or 'false'.\n" "${property}" >&2
                    return 1
                fi
                ;;
            log_file)
                if [[ -z "${value}" || "${value}" == */* && ! -d "$(dirname "${value}")" ]]; then
                    printf "Error: Log file directory does not exist or is not writable: %s\n" "$(dirname "${value}")" >&2
                    return 1
                fi
                ;;
            *)
                printf "Error: Invalid property '%s'.\n" "${property}" >&2
                return 1
                ;;
        esac

        # Assign the value to the associative array
        eval "${instance_name}_props[${property}]='$(printf "%q" "${value}")'"
    }

    # =============================================================================
    # Get a property from a logger instance
    # =============================================================================
    function _Logger_get_property() {
        local instance_name=$1
        local property=$2
        eval "echo \${${instance_name}_props[${property}]}"
    }
fi
