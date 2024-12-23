#!/usr/bin/env bash

# =============================================================================
# NAME        : logging.sh
# DESCRIPTION : Logs bash commands executed in the current session to a log file.
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-08 19:57:22
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-08 19:57:22  | Adam Compton | Initial creation.
# =============================================================================

# Guard to prevent multiple sourcing
if [[ -z "${LOGGING_SH_LOADED:-}" ]]; then
    declare -g LOGGING_SH_LOADED=true

    # =============================================================================
    # Configuration
    # =============================================================================

    # Log file location
    LOG_FILE="$HOME/.bash_commands.log"

    # =============================================================================
    # Utility Functions
    # =============================================================================

    # Ensure the log directory exists and the log file is writable
    ensure_log_file() {
        local log_dir
        log_dir=$(dirname "$LOG_FILE")

        # Create log directory if it doesn't exist
        if ! mkdir -p "$log_dir" 2>/dev/null; then
            echo "Error: Failed to create log directory: $log_dir" >&2
            return 1
        fi

        # Create or touch the log file
        if ! touch "$LOG_FILE" 2>/dev/null; then
            echo "Error: Failed to create or touch log file: $LOG_FILE" >&2
            return 1
        fi

        # Set restrictive permissions on the log file
        if ! chmod 600 "$LOG_FILE" 2>/dev/null; then
            echo "Error: Failed to set permissions on log file: $LOG_FILE" >&2
            return 1
        fi

        return 0
    }

    # Logging function
    log_bash_command() {
        local date_time session_info command tty pid

        # Detect session type (screen, tmux, or TTY)
        if [[ -n "$STY" ]]; then
            # Inside a screen session
            window_num=$(echo "$WINDOW" 2>/dev/null || echo "unknown")
            session_info="screen:$STY:($window_num)"
        elif [[ -n "$TMUX" ]]; then
            # Inside a tmux session
            session_name=$(tmux display-message -p '#S' 2>/dev/null || echo "unknown")
            window_name=$(tmux display-message -p '#I' 2>/dev/null || echo "unknown")
            pane_name=$(tmux display-message -p '#P' 2>/dev/null || echo "unknown")
            session_info="tmux:$session_name[$window_name:$pane_name]"
        else
            # Fallback to TTY and PID
            tty=$(tty 2>/dev/null | sed 's|/dev/||' || echo "unknown")
            pid=$$
            session_info="tty(pid):$tty($pid)"
        fi

        # Retrieve the last executed command from history
        command=$(history 1 | sed -E 's/^ *[0-9]+ *\[[0-9/ :]+\] *//')

        # Prevent duplicate logging
        if [[ "$command" == "$LAST_LOGGED_COMMAND" ]]; then
            return
        fi
        LAST_LOGGED_COMMAND="$command"

        # Write the log entry
        (
            date_time=$(date +"%Y-%m-%d %H:%M:%S")
            flock -n 200 || exit 1
            echo "[$date_time] $session_info # $command" >> "$LOG_FILE"
        ) 200>"$LOG_FILE.lock"
    }

    # =============================================================================
    # Initialization
    # =============================================================================

    # Ensure the log file is properly set up
    if ! ensure_log_file; then
        echo "Error: Logging could not be initialized. Commands will not be logged." >&2
        return 1
    fi

    # Trap DEBUG signal to log each command
    trap 'log_bash_command' DEBUG

    # Inform the user if the logging script is successfully loaded
    echo "Command logging initialized. Log file: $LOG_FILE"
fi
