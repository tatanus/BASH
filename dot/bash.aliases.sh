#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : bash.aliases.sh
# DESCRIPTION : A collection of useful aliases and functions for Bash.
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-08 19:57:22
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-08 19:57:22  | Adam Compton | Initial creation.
# =============================================================================

# Guard to prevent multiple sourcing
if [[ -z "${BASH_ALIAS_SH_LOADED:-}" ]]; then
    declare -g BASH_ALIAS_SH_LOADED=true

    # Source the bash.funcs.sh script if it exists
    [[ -f "${BASH_DIR}/bash.funcs.sh" ]] && source "${BASH_DIR}/bash.funcs.sh"

    # Alias for ncat
    check_command "ncat" && alias nc="ncat"

    # Alias for gsed
    # shellcheck disable=SC2262
    if [[ "$(_get_os)" == "macos" ]]; then
        check_command "gsed" && alias sed="gsed"
    fi

    # Alias for grep with color
    # shellcheck disable=SC2262
    alias grep='grep --color=auto'

    # Alias for ggrep
    # shellcheck disable=SC2262
    if [[ "$(_get_os)" == "macos" ]]; then
        check_command "ggrep" && alias grep="ggrep --color=auto"
    fi

    # Alias and function for eza
    check_command "eza" && alias ls="convert_ls_to_eza"

    # Check and set alias for bat or batcat
    if command -v bat &> /dev/null; then
        alias cat='bat --paging=never --style=plain --theme=ansi'
    elif command -v batcat &> /dev/null; then
        alias cat='batcat --paging=never --style=plain --theme=ansi'
    else
        echo "Neither 'bat' nor 'batcat' is installed. Defauting back to the base 'cat' functionality." >&2
    fi

    # Alias to shorten proxychains4
    check_command "proxychains4" && alias PROXY="proxychains4 -q"

    # Alias to get public IP address using proxychains4 and curl
    if check_command "curl"; then
        alias myip="\${PROXY} curl ifconfig.me/ip"

        # Alias to run 'curl' with a specific user agent string
        alias curl='curl -A "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.90 Safari/537.36" -k'
    fi

    # Alias for dig with short output
    alias dig='dig +short'

    # Alias for wget with resume support
    alias wget='wget -c'

    # List Listeners
    alias listen="netstat -tupan | grep LISTEN"

    # List largest files on filesystem
    function file_hogs() {
        for unit in G M K; do
            # use `command` (or a leading backslash) to bypass any same-file aliases,
            # and wrap the loop var in braces to satisfy SC2250
            command du -ah . \
                | grep "[0-9]${unit}" \
                | sort -nr -k1,1
        done | head -n 11
    }
fi
