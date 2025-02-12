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

    # =============================================================================
    # Functions
    # =============================================================================

    ###############################################################################
    # Source Required Function Scripts
    #
    # Description:
    #   Sources additional function scripts if they exist. These scripts provide
    #   auxiliary functionalities required by the prompt.
    #
    #   - bash.prompt_funcs.sh: Contains helper functions for prompt customization.
    #
    #   If the scripts are not found, warnings are emitted to stderr.
    #
    # Usage:
    #   Automatically sourced during script initialization.
    ###############################################################################
    if [[ -f "${BASH_DIR}"/bash.prompt_funcs.sh ]]; then
        source "${BASH_DIR}"/bash.prompt_funcs.sh
    else
        echo "Warning: ${BASH_DIR}/bash.prompt_funcs.sh not found. Some prompt features may be unavailable." >&2
    fi

    ###############################################################################
    # gen_prompt
    # Generates and sets the dynamic Bash prompt (PS1) with various system and
    # environment information.
    #
    # Description:
    #   Constructs the PS1 variable to include:
    #     - Active session names (TMUX or SCREEN)
    #     - Kerberos credential cache status
    #     - Python virtual environment status
    #     - Current date and time
    #     - Internal and external IP addresses
    #     - User and host information
    #     - Current working directory
    #
    #   The prompt is color-coded for better readability.
    #
    # Usage:
    #   Automatically invoked via PROMPT_COMMAND.
    #
    # Requirements:
    #   - Functions `get_session_name`, `check_session`, `check_kerb_ccache`,
    #     and `check_venv` must be defined and sourced appropriately.
    #
    # Environment Variables:
    #   PROMPT_LOCAL_IP - Stores the internal IP address.
    #   PROMPT_EXTERNAL_IP - Stores the external IP address.
    #   LAST_IP_CHECK - Timestamp of the last IP address check.
    ###############################################################################
    function gen_prompt() {
        # Get the active session name
        session_name=$(get_session_name 2> /dev/null)

        # Construct the prompt
        PS1="\n"
        # SCREEN SESSION STATUS
        PS1+="$(check_session 2> /dev/null)"
        # KERBEROS CREDENTIAL CACHE
        PS1+="$(check_kerb_ccache 2> /dev/null)"
        # PYTHON VENV
        PS1+="$(check_venv 2> /dev/null)"
        # DATE TIME
        PS1+="\[${white}\][\[${light_green}\]\D{%m-%d-%Y} \t\[${white}\]━"
        # INTERNAL IP
        PS1+="\[${white}\][\[${light_blue}\]${PROMPT_LOCAL_IP}\[${white}\]━"
        # EXTERNAL IP
        PS1+="\[${white}\][ext:\[${blue}\]${PROMPT_EXTERNAL_IP}\[${white}\]━"
        # USER@FQDN
        PS1+="\[${white}\][\[${light_red}\]\u@\h\[${white}\]]\n"
        # PATH
        #PS1+="${white}┗━> [${yellow}\w${white}]${reset} \$ \[$(tput sgr0)\]"
        PS1+="\[${white}\]┗━> [\[${yellow}\]\w\[${white}]\]\[${reset}\] \$ \[${reset}\]"

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

    preexec() {
        local date_time_stamp
        date_time_stamp=$(date +"[%D %T]")
        echo
        echo "${date_time_stamp} # $1"
        echo
    }
fi
