#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : logger.sh
# DESCRIPTION : A modular and instance-based logging utility for Bash scripts.
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

    # -----------------------------------------------------------------------------
    # Define colors for screen output
    # -----------------------------------------------------------------------------
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

    # -----------------------------------------------------------------------------
    # Valid logging levels
    # -----------------------------------------------------------------------------
    valid_levels=("debug" "info" "warn" "pass" "fail")

    # -----------------------------------------------------------------------------
    # Validates an instance name to ensure it's a valid Bash variable name
    # -----------------------------------------------------------------------------
    function _validate_instance_name() {
        local name=$1
        if [[ ! "${name}" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
            printf "Error: Invalid instance name '%s'. Must start with a letter or underscore and contain only alphanumeric characters and underscores.\n" "${name}" >&2
            return 1
        fi
    }

    # -----------------------------------------------------------------------------
    # Validates if a given log level is valid
    # -----------------------------------------------------------------------------
    function _validate_log_level() {
        local level=$1
        if [[ ! " ${valid_levels[*]} " =~ ${level} ]]; then
            printf "Error: Invalid log level '%s'. Valid levels are: %s.\n" "${level}" "${valid_levels[*]}" >&2
            return 1
        fi
    }

    # -----------------------------------------------------------------------------
    # Initializes a new logger instance
    # -----------------------------------------------------------------------------
    function Logger_Init() {
        local instance_name=$1
        local log_file=${2:-"${HOME}/${instance_name}.log"}  # Default log file
        local log_level=${3:-"info"}
        local log_to_screen=${4:-"true"}
        local log_to_file=${5:-"true"}

        # Validate instance name
        _validate_instance_name "${instance_name}" || return 1

        # Validate log file path
        if [[ -z "${log_file}" || "${log_file}" == */* && ! -d "$(dirname "${log_file}")" ]]; then
            printf "Error: Log file directory does not exist or is not writable: %s\n" "$(dirname "${log_file}")" >&2
            return 1
        fi

        # Validate log level
        _validate_log_level "${log_level}" || return 1

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

    # -----------------------------------------------------------------------------
    # Generates a timestamp for log entries
    # -----------------------------------------------------------------------------
    function _Logger_timestamp() {
        date +"[%Y-%m-%d %H:%M:%S]"
    }

    # -----------------------------------------------------------------------------
    # Logs a message
    # -----------------------------------------------------------------------------
    function Logger_log() {
        local instance_name="${1:-"default"}"
        local level="${2:="debug"}"
        local message="${3:-""}" # Allow blank messages
        local caller_info="${4:-$(caller 1)}" # Caller information for debug messages

        # Ensure instance_name is provided
        if [[ -z "${instance_name}" ]]; then
            printf "Error: instance_name is required for Logger_log.\n" >&2
            return 1
        fi

        # Validate that the instance exists
        if ! declare -p "${instance_name}_props" &> /dev/null; then
            printf "Error: Logger instance '%s' does not exist.\n" "${instance_name}" >&2
            return 1
        fi

        # Validate the log level
        _validate_log_level "${level}" || return 1

        # Access instance properties using _Logger_get_property
        local log_file
        local log_level
        local log_to_screen
        local log_to_file
        log_file=$(_Logger_get_property "${instance_name}" "log_file")
        log_level=$(_Logger_get_property "${instance_name}" "log_level")
        log_to_screen=$(_Logger_get_property "${instance_name}" "log_to_screen")
        log_to_file=$(_Logger_get_property "${instance_name}" "log_to_file")

        # Define log levels
        local levels
        local priority
        local current_priority
        levels=("debug" "info" "warn" "pass" "fail")
        priority=$(printf '%s\n' "${levels[@]}" | grep -nx "${level}" | cut -d':' -f1)
        current_priority=$(printf '%s\n' "${levels[@]}" | grep -nx "${log_level}" | cut -d':' -f1)

        # Skip logging if the level is lower than the configured level
        if [[ -n "${priority}" && -n "${current_priority}" && "${priority}" -lt "${current_priority}" ]]; then
            return
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

        # Log to file if enabled
        if [[ "${log_to_file}" == "true" ]]; then
            printf "%s\n" "${timestamp} ${prefix} ${formatted_message}" >> "${log_file}" || {
                printf "Error: Failed to write to log file: %s\n" "${log_file}" >&2
                return 1
            }
        fi

        # Log to screen if enabled
        if [[ "${log_to_screen}" == "true" ]]; then
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
    }

    # -----------------------------------------------------------------------------
    # Set a property for a logger instance
    # -----------------------------------------------------------------------------
    function _Logger_set_property() {
        local instance_name=$1
        local property=$2
        local value=$3

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

    # -----------------------------------------------------------------------------
    # Get a property from a logger instance
    # -----------------------------------------------------------------------------
    function _Logger_get_property() {
        local instance_name=$1
        local property=$2
        eval "echo \${${instance_name}_props[${property}]}"
    }
fi

###############################################################################
# Example usage
###############################################################################

# # Create two logger instances
# Logger_Init "logger1" "/tmp/logger1.log" "debug" "true" "true" || exit 1
# Logger_Init "logger2" "/tmp/logger2.log" "debug" "true" "false" || exit 1

# # Use instance-specific methods
# logger1.info "This is an info message for logger1."
# logger1.warn "This is a warning message for logger1."
# logger2.info "This is an info message for logger2 (won't log due to level)."
# logger2.warn "This is a warning message for logger2."
# logger1.debug "This is a debug message for logger1."
# logger2.fail "This is a failure message for logger2."
# logger1.debug "This is a debug message"
# logger2.debug
# logger2.info
# logger2.warn
# logger2.pass
# logger2.fail

# logger2.debug ""
# logger2.info ""
# logger2.warn ""
# logger2.pass ""
# logger2.fail ""
