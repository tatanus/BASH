#!/usr/bin/env bash

# =============================================================================
# NAME        : logging.sh
# DESCRIPTION : 
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

    # Log file location
    LOG_FILE="$HOME/.bash_commands.log"

    # Ensure log directory exists
    mkdir -p "$(dirname "$LOG_FILE")"
    touch "$LOG_FILE"
    chmod 600 "$LOG_FILE"

    # Logging function
    log_bash_command() {
        local date_time
        local session_info
        local command
        local tty
        local pid

        # Check if the command is executed inside a screen session
        if [ -n "$STY" ]; then
            window_num=$(echo "$WINDOW" 2>/dev/null)
            session_info="screen:$STY:($window_num)"
        elif [ -n "$TMUX" ]; then
            # Inside a tmux session
            session_name=$(tmux display-message -p '#S')  # Get the tmux session name
            window_name=$(tmux display-message -p '#I')  # Get the tmux window index
            pane_name=$(tmux display-message -p '#P')    # Get the tmux pane index
            tmux_info="tmux:$session_name[$window_name:$pane_name]"
            session_info="$tmux_info"
        else
            # Get TTY and PID
            tty=$(tty | sed 's|/dev/||')
            pid=$$
            session_info="tty(pid):$tty($pid)"
        fi

        # Get the last command from the history (without the added datetime)
        command=$(history 1 | sed -E 's/^ *[0-9]+ *\[[0-9/ :]+\] *//')

        # Prevent duplicate logging caused by DEBUG traps firing multiple times
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

    # Trap DEBUG signal to log each command
    trap 'log_bash_command' DEBUG
fi