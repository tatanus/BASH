#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : bash.prompt.sh
# DESCRIPTION : Customizes the Bash prompt with dynamic information such as
#               session names, IP addresses, and environment details.
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-08 19:57:22
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-08 19:57:22  | Adam Compton | Initial creation.
# 2025-04-24           | Adam Compton | Unified all comment blocks.
# =============================================================================

# Guard to prevent multiple sourcing
if [[ -z "${BASH_PROMPT_SH_LOADED:-}" ]]; then
    declare -g BASH_PROMPT_SH_LOADED=true

    # =============================================================================
    # Configuration
    # =============================================================================

    # Define colors using tput for compatibility across systems
    light_green=$(tput setaf 2)
    light_blue=$(tput setaf 6)
    blue=$(tput setaf 4)
    light_red=$(tput setaf 1)
    yellow=$(tput setaf 3)
    orange=$(tput setaf 214 2> /dev/null || tput setaf 3)  # Fallback to yellow if 214 isn't supported
    white=$(tput setaf 7)
    reset=$(tput sgr0)

    # Variables for IPs
    PROMPT_LOCAL_IP="${PROMPT_LOCAL_IP:-Unavailable}"
    PROMPT_EXTERNAL_IP="${PROMPT_EXTERNAL_IP:-Unavailable}"
    LAST_LOCAL_IP_CHECK=0
    LAST_EXT_IP_CHECK=0

    ###############################################################################
    # Name: validate_bash_dir
    # Short Description: Ensure BASH_DIR is set, default to HOME if unset.
    #
    # Long Description:
    #   Checks whether the BASH_DIR variable is defined and non-empty. If it is
    #   unset or empty, emits a warning and assigns BASH_DIR to the user's home
    #   directory.
    #
    # Parameters:
    #   None
    #
    # Requirements:
    #   None
    #
    # Usage:
    #   validate_bash_dir  # runs automatically at script start
    #
    # Returns:
    #   - Exports a non-empty BASH_DIR variable.
    ###############################################################################
    if [[ -z "${BASH_DIR:-}" ]]; then
        echo "Warning: BASH_DIR is not set; defaulting to ~/ (${HOME})" >&2
        BASH_DIR="${HOME}"
    fi

    # =============================================================================
    # Name: source_prompt_funcs
    # Short Description: Sources additional prompt function scripts.
    #
    # Long Description:
    #   Sources bash.prompt_funcs.sh from the BASH_DIR directory to load helper
    #   functions for prompt customization. Emits a warning if the file is missing.
    #
    # Parameters:
    #   None
    #
    # Requirements:
    #   - BASH_DIR variable must be defined.
    #   - bash.prompt_funcs.sh must exist in BASH_DIR.
    #
    # Usage:
    #   Automatically invoked during script initialization.
    #
    # Returns:
    #   - None (sources file or prints warning).
    # =============================================================================
    if [[ -f "${BASH_DIR}"/bash.prompt_funcs.sh ]]; then
        source "${BASH_DIR}"/bash.prompt_funcs.sh
    else
        echo "Warning: ${BASH_DIR}/bash.prompt_funcs.sh not found. Some prompt features may be unavailable." >&2
    fi

    # =============================================================================
    # Name: gen_prompt
    # Short Description: Generates and sets the dynamic Bash prompt (PS1).
    #
    # Long Description:
    #   Constructs the PS1 variable to include:
    #     - Git status (branch, dirty/clean)
    #     - Active TMUX/SCREEN sessions
    #     - Kerberos credential cache status
    #     - Python virtual environment status
    #     - Current date and time
    #     - Internal and external IP addresses
    #     - User and host information
    #     - Current working directory
    #   All segments are color-coded for readability.
    #
    # Parameters:
    #   None
    #
    # Requirements:
    #   - Functions: check_git, check_session, check_kerb_ccache, check_venv,
    #     get_local_ip, get_external_ip must be defined.
    #   - Color variables and PROMPT_LOCAL_IP, PROMPT_EXTERNAL_IP,
    #     LAST_LOCAL_IP_CHECK, LAST_EXT_IP_CHECK must exist.
    #
    # Usage:
    #   Automatically invoked via PROMPT_COMMAND.
    #
    # Returns:
    #   - None (sets PS1 global variable).
    # =============================================================================
    function gen_prompt() {
        # Get the active session name
        session_name=$(get_session_name 2> /dev/null)

        # Construct the prompt
        PS1="\n\[${white}\]┏━"
        # GIT STATUS
        PS1+="$(check_git 2> /dev/null)"
        # SCREEN SESSION STATUS
        PS1+="$(check_session 2> /dev/null)"
        # KERBEROS CREDENTIAL CACHE
        PS1+="$(check_kerb_ccache 2> /dev/null)"
        # PYTHON VENV
        PS1+="$(check_venv 2> /dev/null)"
        PS1+="\[${white}\]["
        # DATE TIME
        PS1+="\[${light_green}\]\D{%m-%d-%Y} \t"
        PS1+="\[${white}\]]━["
        # INTERNAL IP
        PS1+="${PROMPT_LOCAL_IP}"
        PS1+="\[${white}\]]━["
        # EXTERNAL IP
        PS1+="ext:\[${blue}\]${PROMPT_EXTERNAL_IP}"
        PS1+="\[${white}\]]━["
        # USER@FQDN
        PS1+="\[${light_red}\]\u@\h"
        PS1+="\[${white}\]]"
        PS1+="\n"
        # PATH
        PS1+="\[${white}\]┗━> [\[${yellow}\]\w\[${white}\]] \$ \[${reset}\]"

        export PS1="${PS1}"
    }

    # Call get_local_ip if it's been more than 5 minutes
    if (($(date +%s) - LAST_LOCAL_IP_CHECK > 300)); then
        PROMPT_LOCAL_IP=$(get_local_ip 2> /dev/null || echo "Unavailable")
        LAST_LOCAL_IP_CHECK=$(date +%s)
    fi

    # Call get_external_ip if it's been more than 60 minutes
    if (($(date +%s) - LAST_EXT_IP_CHECK > 3600)); then
        PROMPT_EXTERNAL_IP=$(get_external_ip 2> /dev/null || echo "Unavailable")
        LAST_EXT_IP_CHECK=$(date +%s)
    fi

    # Append to PROMPT_COMMAND to avoid overwriting
    PROMPT_COMMAND="${PROMPT_COMMAND:+${PROMPT_COMMAND}; }gen_prompt"

    # Preexec setup
    if [[ -f "${BASH_DIR}"/bash-preexec.sh ]]; then
        source "${BASH_DIR}"/bash-preexec.sh
    else
        echo "Warning: ${BASH_DIR}/bash-preexec.sh not found. Preexec functionality may be unavailable." >&2
    fi

    # =============================================================================
    # Name: preexec
    # Short Description: Logs each command before execution with timestamp.
    #
    # Long Description:
    #   A preexec hook that prints a timestamped log line for each command about
    #   to be executed, aiding in debugging and auditing shell activity.
    #
    # Parameters:
    #   $1 - The command line string to be executed.
    #
    # Requirements:
    #   - The bash-preexec framework must be sourced successfully.
    #
    # Usage:
    #   Automatically invoked before each command when bash-preexec is active.
    #
    # Returns:
    #   - None (outputs timestamped command log to stdout).
    # =============================================================================
    function preexec() {
        local date_time_stamp
        date_time_stamp=$(date +"[%D %T]")
        echo
        echo "${date_time_stamp} # $1"
        echo
    }
fi
