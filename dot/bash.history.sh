#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : bash.history.sh
# DESCRIPTION : Logs bash commands executed in the current session to a history file.
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-08 19:57:22
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-08 19:57:22  | Adam Compton | Initial creation.
# =============================================================================

# Guard to prevent multiple sourcing
if [[ -z "${BASH_HISTORY_SH_LOADED:-}" ]]; then
    declare -g BASH_HISTORY_SH_LOADED=true

    # Initialize LAST_LOGGED_COMMAND to an empty value
    declare -g LAST_LOGGED_COMMAND=""

    # =============================================================================
    # Configuration
    # =============================================================================

    # Log file location
    if [[ -z "${BASH_LOG_DIR:-}" ]]; then
        HISTORY_FILE="${HOME}/.combined_history.log"
    else
        HISTORY_FILE="${BASH_LOG_DIR}/bash_history.log"
    fi

    LOCK_FILE="${HISTORY_FILE}.lock"

    # =============================================================================
    # Utility Functions
    # =============================================================================

    # Ensure the log directory exists and the history file is writable
    function ensure_history_file() {
        local history_dir
        history_dir=$(dirname "${HISTORY_FILE}")

        # Create log directory if it doesn't exist
        if ! mkdir -p "${history_dir}" 2> /dev/null; then
            echo "Error: Failed to create log directory: ${history_dir}" >&2
            return 1
        fi

        # Create or touch the log file
        if ! touch "${HISTORY_FILE}" 2> /dev/null; then
            echo "Error: Failed to create or touch log file: ${HISTORY_FILE}" >&2
            return 1
        fi

        # Set restrictive permissions on the log file
        if ! chmod 600 "${HISTORY_FILE}" 2> /dev/null; then
            echo "Error: Failed to set permissions on log file: ${HISTORY_FILE}" >&2
            return 1
        fi

        return 0
    }

    # Basic lock fallback function
    function basic_lock() {
        if [[ -f "${LOCK_FILE}" ]]; then
            # Check if the lock file is stale
            local pid
            pid=$(< "${LOCK_FILE}")
            if ! kill -0 "${pid}" 2> /dev/null; then
                # Stale lock, remove it
                rm -f "${LOCK_FILE}"
            else
                # Lock is active, exit
                return 1
            fi
        fi
        # Create lock file with current PID
        echo "$$" > "${LOCK_FILE}"
        return 0
    }

    # Logging function
    function log_bash_command() {
        local date_time session_info command tty pid

        # Detect session type (screen, tmux, or TTY)
        if [[ -n "${STY:-}" ]]; then
            # Inside a screen session
            window_num=$(echo "${WINDOW}" 2> /dev/null || echo "unknown")
            session_info="screen:${STY:-}:(${window_num})"
        elif [[ -n "${TMUX:-}" ]]; then
            # Inside a tmux session
            session_name=$(tmux display-message -p '#S' 2> /dev/null || echo "unknown")
            window_name=$(tmux display-message -p '#I' 2> /dev/null || echo "unknown")
            pane_name=$(tmux display-message -p '#P' 2> /dev/null || echo "unknown")
            session_info="tmux:${session_name}(${window_name}:${pane_name})"
        else
            # Fallback to TTY and PID
            tty=$(tty 2> /dev/null | sed 's|/dev/||' || echo "unknown")
            pid=$$
            session_info="tty(pid):${tty}(${pid})"
        fi

        # Retrieve the last executed command from history
        command=$(history 1 | sed -E 's/^ *[0-9]+ *\[[0-9/ :]+\] *//')

        # Prevent duplicate logging
        if [[ "${command}" == "${LAST_LOGGED_COMMAND}" ]]; then
            return
        fi
        LAST_LOGGED_COMMAND="${command}"

        # Write the log entry
        date_time=$(date +"%Y-%m-%d %H:%M:%S")
        if command -v flock &> /dev/null; then
            (   
                flock -n 200 || exit 1
                echo "[${date_time}] ${session_info} # ${command}" >> "${HISTORY_FILE}"
            ) 200> "${LOCK_FILE}"
        else
            if basic_lock; then
                echo "[${date_time}] ${session_info} # ${command}" >> "${HISTORY_FILE}"
                basic_unlock
            else
                echo "Error: Could not acquire lock. Skipping log entry." >&2
            fi
        fi
    }

    # =============================================================================
    # Initialization
    # =============================================================================

    # Ensure the log file is properly set up
    if ! ensure_history_file; then
        echo "Error: Logging could not be initialized. Commands will not be logged." >&2
        return 1
    fi

    # Trap DEBUG signal to log each command
    trap 'log_bash_command' DEBUG

    # Inform the user if the logging script is successfully loaded
    echo "Command logging initialized. Log file: ${HISTORY_FILE}"
fi
