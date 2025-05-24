#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : bash.prompt_funcs.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-08 19:57:22
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-08 19:57:22  | Adam Compton | Initial creation.
# 2025-04-24           | Adam Compton | Unified all function comment blocks.
# =============================================================================

# Guard to prevent multiple sourcing
if [[ -z "${BASH_PROMPT_FUNCS_SH_LOADED:-}" ]]; then
    declare -g BASH_PROMPT_FUNCS_SH_LOADED=true

    ###############################################################################
    # Name: check_venv
    # Short Description: Checks if the user is in a Python virtual environment.
    #
    # Long Description:
    #   Determines if the VIRTUAL_ENV environment variable is set, indicating an
    #   active Python virtual environment. If active, prints the environment path
    #   formatted with color codes for inclusion in the Bash prompt.
    #
    # Parameters:
    #   None
    #
    # Requirements:
    #   - Color variables (e.g., ${white}, ${light_blue}) must be defined in the
    #     environment where this function is sourced.
    #
    # Usage:
    #   check_venv
    #
    # Returns:
    #   - Prints the virtual environment information if active.
    #   - No output if not in a virtual environment.
    ###############################################################################
    function check_venv() {
        if [[ -n "${VIRTUAL_ENV}" ]]; then
            echo "\[${white}\][\[${light_blue}\]Python VENV = \[${light_blue}\]${VIRTUAL_ENV}\[${white}\]]"
            echo -e "\[${white}\]┣━"
        fi
    }

    ###############################################################################
    # Name: check_kerb_ccache
    # Short Description: Checks if a Kerberos credential cache is set.
    #
    # Long Description:
    #   Determines if the KRB5CCNAME environment variable is set, indicating an
    #   active Kerberos credential cache. If set, prints the cache name formatted
    #   with color codes for inclusion in the Bash prompt.
    #
    # Parameters:
    #   None
    #
    # Requirements:
    #   - Color variables (e.g., ${white}, ${light_red}) must be defined in the
    #     environment where this function is sourced.
    #
    # Usage:
    #   check_kerb_ccache
    #
    # Returns:
    #   - Prints the Kerberos credential cache information if set.
    #   - No output if not set.
    ###############################################################################
    function check_kerb_ccache() {
        if [[ -n "${KRB5CCNAME}" ]]; then
            echo "\[${white}\][\[${light_red}\]KRB5CCNAME = \[${light_red}\]${KRB5CCNAME}\[${white}\]]"
            echo -e "\[${white}\]┣━"
        fi
    }

    ###############################################################################
    # Name: check_git
    # Short Description: Displays current Git branch and dirty status for PS1.
    #
    # Long Description:
    #   Checks if the current directory is inside a Git working tree. If so,
    #   retrieves the branch or tag name, parses the remote origin URL into host
    #   and path, and summarizes uncommitted changes. Outputs a color-coded
    #   status string for inclusion in the Bash prompt.
    #
    # Parameters:
    #   None
    #
    # Requirements:
    #   - git must be installed and available in PATH.
    #
    # Usage:
    #   check_git
    #
    # Returns:
    #   - Prints a formatted Git status line if in a repository.
    #   - No output (exit code 0) if not in a Git repository.
    ###############################################################################
    function check_git() {
        # Ensure we're in a Git working tree
        if ! git rev-parse --is-inside-work-tree &> /dev/null; then
            return 0  # Not a Git repo, exit silently
        fi

        # Get branch name
        branch=$(git symbolic-ref --quiet --short HEAD 2> /dev/null || git describe --tags --exact-match 2> /dev/null)
        [[ -z "${branch}" ]] && branch="unknown"

        # Extract remote origin info
        origin_url=$(git config --get remote.origin.url 2> /dev/null)
        if [[ "${origin_url}" =~ ^git@([^:]+):([^/]+/[^/]+)(\.git)?$ ]]; then
            # SSH style: git@host:org/repo.git
            host="${BASH_REMATCH[1]}"
            path="${BASH_REMATCH[2]}"
        elif [[ "${origin_url}" =~ ^https?://([^/]+)/([^/]+/[^/.]+)(\.git)?$ ]]; then
            # HTTPS style: https://host/org/repo.git
            host="${BASH_REMATCH[1]}"
            path="${BASH_REMATCH[2]}"
        else
            host="unknown"
            path="local"
        fi

        # Combine to host/org/repo
        origin="${host}/${path}"

        # Attempt to get the current branch or tag
        branch=$(git symbolic-ref --quiet --short HEAD 2> /dev/null || git describe --tags --exact-match 2> /dev/null)
        if [[ -z "${branch}" ]]; then
            branch="unknown"
        fi

        # Check if there are uncommitted changes
        if git_status=$(git status --porcelain 2> /dev/null); then
            if [[ -n "${git_status}" ]]; then
                # Dirty: Count types of changes
                modified_count=$(echo "${git_status}" | grep -cE '^[ MARC][MD]')
                added_count=$(echo "${git_status}" | grep -cE '^[ MARC]A')
                deleted_count=$(echo "${git_status}" | grep -cE '^[ MARC]D')

                # Format status string
                dirty_summary=""
                [[ ${modified_count} -gt 0 ]] && dirty_summary+=" M${modified_count}"
                [[ ${added_count} -gt 0 ]] && dirty_summary+=" A${added_count}"
                [[ ${deleted_count} -gt 0 ]] && dirty_summary+=" D${deleted_count}"

                echo "\[${white}\][\[${light_blue}\]GIT ${origin}:${branch} \[${light_red}\]✗${dirty_summary}\[${white}\]]"
            else
                # Repo is clean
                echo "\[${white}\][\[${light_blue}\]GIT ${origin}:${branch} \[${light_green}\]✔\[${white}\]]"
            fi
        else
            echo "\[${white}\][\[${light_blue}\]GIT ${origin}:${branch} \[${orange}\]?\[${white}\]]"
        fi

        # Visual indicator for continuation line
        echo -e "\[${white}\]┣━"
    }

    ###############################################################################
    # Name: check_session
    # Short Description: Checks for active TMUX or SCREEN sessions.
    #
    # Long Description:
    #   Detects whether the shell is running inside a TMUX or SCREEN session.
    #   Retrieves the session names and prints them, color-coded, for the prompt.
    #
    # Parameters:
    #   None
    #
    # Requirements:
    #   - Color variables (e.g., ${white}, ${yellow}) must be defined.
    #   - A helper function get_session_name (if used) must be sourced.
    #
    # Usage:
    #   check_session
    #
    # Returns:
    #   - Prints session information if inside TMUX or SCREEN.
    #   - No output if not in any session.
    ###############################################################################
    function check_session() {
        SESSION_STATUS=""

        # TMUX: session name and current window:index
        if [[ -n "${TMUX:-}" ]]; then
            local tmux_name tmux_win
            tmux_name=$(tmux display-message -p '#S')
            tmux_win=$(tmux display-message -p '#I:#W')
            SESSION_STATUS+="[\[${yellow}\]TMUX=${tmux_name}:${tmux_win}\[${white}\]]"
        fi

        # SCREEN: session name (after the first dot in STY) and window number from $WINDOW
        if [[ -n "${STY:-}" ]]; then
            local full_sty="${STY}"
            # session name is everything after the first dot in STY
            local screen_name="${full_sty#*.}"
            # window number as set by GNU Screen
            local screen_win="${WINDOW:-?}"
            SESSION_STATUS+="[\[${yellow}\]SCREEN=${screen_name}:${screen_win}\[${white}\]]"
        fi

        if [[ -n "${SESSION_STATUS}" ]]; then
            SESSION_STATUS+="\[${white}\]\n┣━"
        fi

        echo -e "${SESSION_STATUS}"
    }

    ###############################################################################
    # Name: is_dhcp_static
    # Short Description: Determines if an interface is DHCP or static.
    #
    # Long Description:
    #   Examines the network configuration of a given interface across Linux
    #   (NetworkManager, systemd-networkd, /etc/network/interfaces) and macOS
    #   (networksetup) to report whether it uses DHCP or a static IP.
    #
    # Parameters:
    #   $1 - Interface name (e.g., "eth0", "en0")
    #
    # Requirements:
    #   - Helper function _get_os must be defined.
    #   - On macOS, the networksetup utility must be available.
    #
    # Usage:
    #   ip_type=$(is_dhcp_static "eth0")
    #
    # Returns:
    #   - Prints "DHCP" or "Static" on success.
    #   - Exits with status 1 and prints an error message on failure.
    ###############################################################################
    function is_dhcp_static() {
        # Ensure the interface is provided
        local interface=$1
        if [[ -z "${interface}" ]]; then
            echo "Error: No interface specified." >&2
            return 1
        fi

        # Detect OS type
        local os_type
        os_type=$(_get_os)

        # Handle Linux systems
        if [[ "${os_type}" == "linux" || "${os_type}" == "ubuntu" ]]; then
            # Check if nmcli is available and NetworkManager is active
            if command -v nmcli &> /dev/null && systemctl is-active NetworkManager &> /dev/null; then
                local connection_profile
                connection_profile=$(nmcli -g GENERAL.CONNECTION device show "${interface}" 2> /dev/null)

                if [[ "${connection_profile}" != "--" && -n "${connection_profile}" ]]; then
                    local ip_method
                    ip_method=$(nmcli -g ipv4.method connection show "${connection_profile}" 2> /dev/null)

                    case "${ip_method}" in
                        auto)
                            echo "DHCP"
                            return 0
                            ;;
                        manual)
                            echo "Static"
                            return 0
                            ;;
                        *)
                            : # do nothing
                            ;;
                    esac
                fi
            fi

            # Check if systemd-networkd is active
            if systemctl is-active systemd-networkd &> /dev/null; then
                local config_file
                config_file=$(find /etc/netplan/ -name "*.yaml" -print -quit)

                if [[ -n "${config_file}" ]]; then
                    local config
                    config=$(grep -A3 "${interface}:" "${config_file}" 2> /dev/null)

                    if echo "${config}" | grep -q "dhcp4: true"; then
                        echo "DHCP"
                        return 0
                    elif echo "${config}" | grep -q "addresses:"; then
                        echo "Static"
                        return 0
                    fi
                fi
            fi

            # Fall back to /etc/network/interfaces
            if [[ -f /etc/network/interfaces ]]; then
                local config
                config=$(grep -A3 "iface ${interface}" /etc/network/interfaces 2> /dev/null)

                if echo "${config}" | grep -q "dhcp"; then
                    echo "DHCP"
                    return 0
                elif echo "${config}" | grep -q "static"; then
                    echo "Static"
                    return 0
                fi
            fi

            echo "Unknown (unable to determine DHCP or Static configuration)." >&2
            return 1

        # Handle macOS systems
        elif [[ "${os_type}" == "macos" ]]; then
            # Check if the 'networksetup' command is available
            if ! command -v networksetup &> /dev/null; then
                echo "Error: 'networksetup' command is not available." >&2
                exit 1
            fi

            # Capture the list of hardware ports and devices
            resulting_list=$(networksetup -listallhardwareports | awk '
                /^Hardware Port:/ { port_name = substr($0, index($0, $3)) }
                /^Device:/ { device_name = $2; print device_name "," port_name }
            ')

            # Ensure the resulting list is not empty
            if [[ -z "${resulting_list}" ]]; then
                echo "Error: No hardware ports or devices found." >&2
                exit 1
            fi

            # Process each line in the list
            while IFS= read -r line; do
                local device="${line%%,*}"
                local port_name="${line#*,}"

                if [[ "${interface}" == "${device}" ]]; then
                    # Get network configuration for the matching port
                    local config
                    config=$(networksetup -getinfo "${port_name}" 2> /dev/null)

                    if [[ $? -ne 0 ]]; then
                        echo "Error: Failed to get network information for '${port_name}' (${device})." >&2
                        return 1
                    fi

                    if echo "${config}" | grep -q "DHCP Configuration"; then
                        echo "DHCP"
                        return 0
                    elif echo "${config}" | grep -q "Manually configured"; then
                        echo "Static"
                        return 0
                    else
                        echo "Unknown"
                        return 1
                    fi
                fi
            done <<< "${resulting_list}"

            echo "Unknown"
            return 1
        else
            echo "Unsupported OS: ${os_type}" >&2
            return 1
        fi
    }

    ###############################################################################
    # Name: get_local_ip
    # Short Description: Retrieves and formats local IP addresses.
    #
    # Long Description:
    #   Enumerates network interfaces (excluding lo*, docker*, etc.), fetches their
    #   IP addresses, determines DHCP vs. static via is_dhcp_static, and builds a
    #   color-coded string for the Bash prompt. Exports PROMPT_LOCAL_IP.
    #
    # Parameters:
    #   None
    #
    # Requirements:
    #   - ip or ifconfig must be available.
    #   - is_dhcp_static must be defined and available.
    #
    # Usage:
    #   get_local_ip
    #
    # Returns:
    #   - Prints and exports PROMPT_LOCAL_IP on success.
    #   - Returns 1 if no valid interfaces are found or an error occurs.
    ###############################################################################
    function get_local_ip() {
        # Define interfaces to exclude
        local excluded_interfaces=("lo*" "docker*" "virbr*" "vnet*" "tun*" "tap*" "br-*" "ip6tnl*" "sit*")
        local interfaces=""
        local result=""
        local iface ip dhcp

        # Check for required commands
        if command -v ip &> /dev/null; then
            # Get network interfaces and IPs using 'ip'
            interfaces=$(ip -o addr show | awk '$3 == "inet" && $4 != "127.0.0.1/8" {print $2,$4}')
        elif command -v ifconfig &> /dev/null; then
            # Get network interfaces and IPs using 'ifconfig'
            interfaces=$(ifconfig | awk '/^[a-zA-Z0-9]+:/ { iface=$1; next } /inet / && $2 != "127.0.0.1" { print iface,$2 }' | sed 's/://')
        else
            echo "Error: Neither 'ip' nor 'ifconfig' command is available." >&2
            return 1
        fi

        # Check if any interfaces were found
        if [[ -z "${interfaces}" ]]; then
            return 1
        fi

        # Parse and filter interfaces
        while IFS= read -r line; do
            iface=$(echo "${line}" | awk '{print $1}')
            ip=$(echo "${line}" | awk '{print $2}' | cut -d'/' -f1)

            # Skip excluded interfaces using glob matching
            local exclude=0
            for pattern in "${excluded_interfaces[@]}"; do
                if [[ "${iface}" == "${pattern}" ]]; then
                    exclude=1
                    break
                fi
            done
            [[ ${exclude} -eq 1 ]] && continue

            # Determine if the interface is using DHCP or static
            if command -v is_dhcp_static &> /dev/null; then
                dhcp=$(is_dhcp_static "${iface}")
            else
                dhcp="unknown" # Fallback if is_dhcp_static is not defined
            fi

            # Append result (color variables should be defined elsewhere in the script)
            result+="\[${light_blue}\]${iface}\[${yellow}\](${dhcp})\[${white}\]:\[${blue}\]${ip}\[${white}\], "
        done <<< "${interfaces}"

        # Remove trailing comma and space
        export PROMPT_LOCAL_IP="${result%, }"

        # Check if result is empty (e.g., all interfaces excluded)
        if [[ -z "${PROMPT_LOCAL_IP}" ]]; then
            return 1
        fi

        # Output the result
        echo "${PROMPT_LOCAL_IP}"
    }

    ###############################################################################
    # Name: get_external_ip
    # Short Description: Fetches and caches the external IPv4 address.
    #
    # Long Description:
    #   Checks a cache file (/tmp/external_ip.cache) for a recent IP (<10m). If
    #   stale or missing, retrieves a fresh IP via ifconfig.me using curl or wget,
    #   validates, caches, exports PROMPT_EXTERNAL_IP, and prints it.
    #
    # Parameters:
    #   None
    #
    # Requirements:
    #   - curl or wget must be installed.
    #
    # Usage:
    #   get_external_ip
    #
    # Returns:
    #   - Prints and exports PROMPT_EXTERNAL_IP on success.
    #   - Returns non-zero on any failure, printing an error message.
    ###############################################################################
    function get_external_ip() {
        local cache_file="/tmp/external_ip.cache"
        local external_ip=""
        local now
        local last_modified
        local age_sec

        # If the cache file exists, check its age
        if [[ -f "${cache_file}" ]]; then
            now=$(date +%s)
            # Using 'stat' to get the last modification time in epoch seconds
            last_modified=$(stat -c '%Y' "${cache_file}" 2> /dev/null || echo 0)
            age_sec=$((now - last_modified))

            # If the cache file is younger than 600 seconds (10 minutes), try to use it
            if ((age_sec < 600)); then
                external_ip="$(< "${cache_file}")"
                # Validate the cached IP
                if [[ "${external_ip}" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                    export PROMPT_EXTERNAL_IP="${external_ip}"
                    echo "${PROMPT_EXTERNAL_IP}"
                    return 0
                else
                    # Cache is invalid; remove it so we can attempt a fresh fetch
                    rm -f "${cache_file}"
                fi
            fi
        fi

        # --------------------------------------------------------------------
        # Cache is missing, stale, or invalid — fetch a new IP
        # --------------------------------------------------------------------
        if command -v curl &> /dev/null; then
            external_ip="$(curl -4 -s --max-time 5 https://ifconfig.me/ip || true)"
        elif command -v wget &> /dev/null; then
            external_ip="$(wget -4 -qO- --timeout=5 https://ifconfig.me/ip || true)"
        else
            echo "Error: Neither curl nor wget is installed or available." >&2
            return 1
        fi

        # Validate the fetched IP
        if [[ -z "${external_ip}" ]]; then
            echo "Error: Empty response fetching external IP." >&2
            return 1
        fi

        if [[ ! "${external_ip}" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            echo "Error: Invalid IPv4 address format: '${external_ip}'" >&2
            return 1
        fi

        # --------------------------------------------------------------------
        # Cache the valid IP
        # --------------------------------------------------------------------
        echo "${external_ip}" > "${cache_file}"

        # Export and print the result
        export PROMPT_EXTERNAL_IP="${external_ip}"
        echo "${PROMPT_EXTERNAL_IP}"
        return 0
    }
fi
