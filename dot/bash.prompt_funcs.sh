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
# =============================================================================

# Guard to prevent multiple sourcing
if [[ -z "${BASH_PROMPT_FUNCS_SH_LOADED:-}" ]]; then
    declare -g BASH_PROMPT_FUNCS_SH_LOADED=true

    ###############################################################################
    # check_venv
    # Checks if the user is in a Python virtual environment.
    #
    # Description:
    #   Determines if the `VIRTUAL_ENV` environment variable is set, indicating an
    #   active Python virtual environment. If active, it prints the environment path
    #   formatted with color codes for inclusion in the Bash prompt.
    #
    # Requirements:
    #   - Color variables (e.g., `${white}`, `${light_blue}`) must be defined in the
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
            echo "${white}[${light_blue}Python VENV = ${light_blue}${VIRTUAL_ENV}${white}]"
            echo -e "${white}┣━"
        fi
    }

    ###############################################################################
    # check_kerb_ccache
    # Checks if a Kerberos credential cache is set.
    #
    # Description:
    #   Determines if the `KRB5CCNAME` environment variable is set, indicating an
    #   active Kerberos credential cache. If set, it prints the cache name formatted
    #   with color codes for inclusion in the Bash prompt.
    #
    # Requirements:
    #   - Color variables (e.g., `${white}`, `${light_red}`) must be defined in the
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
            echo "${white}[${light_red}KRB5CCNAME = ${light_red}${KRB5CCNAME}${white}]"
            echo -e "${white}┣━"
        fi
    }

    ###############################################################################
    # check_session
    # Checks for active TMUX or SCREEN sessions and formats their names for the prompt.
    #
    # Description:
    #   Detects if the user is currently within a TMUX or SCREEN session. If active,
    #   it retrieves the session names and formats them with color codes for inclusion
    #   in the Bash prompt.
    #
    # Requirements:
    #   - Color variables (e.g., `${white}`, `${yellow}`) must be defined in the
    #     environment where this function is sourced.
    #   - Function `get_session_name` must be defined and sourced appropriately.
    #
    # Usage:
    #   check_session
    #
    # Returns:
    #   - Prints the session information formatted for the prompt if active.
    #   - Prints an empty string if no sessions are active.
    ###############################################################################
    function check_session() {
        SESSION_STATUS="${white}┏━"

        # Check if we are in either a TMUX or SCREEN session
        if [[ -n "${TMUX:-}" ]] || [[ -n "${STY:-}" ]]; then
            # Check if we are in a tmux session
            if [[ -n "${TMUX:-}" ]]; then
                TMUX_SESSION=$(tmux display-message -p '#S')
                SESSION_STATUS+="[${yellow}TMUX = ${TMUX_SESSION}${white}]"
            fi

            # Check if we are in a screen session
            if [[ -n "${STY:-}" ]]; then
                SCREEN_SESSION=$(echo "${STY:-}" | awk -F '.' '{print $2}')
                SESSION_STATUS+="[${yellow}SCREEN = ${SCREEN_SESSION}${white}]"
            fi

            SESSION_STATUS+="\n${white}┣━"
        fi

        echo -e "${SESSION_STATUS}"
    }

    ###############################################################################
    # is_dhcp_static
    # Determines if a network interface is configured for DHCP or Static IP.
    #
    # Description:
    #   Analyzes the network configuration of a specified interface to determine
    #   whether it is using DHCP or has a static IP assignment. Supports various
    #   configurations on Linux (NetworkManager, systemd-networkd, netplan, /etc/network/interfaces)
    #   and macOS (networksetup).
    #
    # Parameters:
    #   $1 - The name of the network interface to check (e.g., "eth0", "en0").
    #
    # Requirements:
    #   - Function `_get_os` must be defined and sourced appropriately.
    #   - On macOS, the `networksetup` command must be available.
    #
    # Usage:
    #   ip_type=$(is_dhcp_static "eth0")
    #   echo "Interface eth0 is using: ${ip_type}"
    #
    # Returns:
    #   - Prints "DHCP" or "Static" based on the interface configuration.
    #   - Prints an error message and exits with status `1` if unable to determine.
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

    # ----------------------------------------------------------------------
    # get_local_ip
    # ----------------------------------------------------------------------
    # - Retrieves local IP addresses from available interfaces, excluding
    #   loopback and virtual interfaces (lo*, docker*, etc.).
    # - Optionally calls is_dhcp_static to label each interface as DHCP/Static.
    # - Exports the combined info in PROMPT_LOCAL_IP and prints it to stdout.
    # - Returns 1 if no valid interfaces are found.
    # ----------------------------------------------------------------------
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
            for pattern in "${excluded_interfaces[@]}"; do
                if [[ "${iface}" == "${pattern}" ]]; then
                    continue 2 # Skip to the next line in the parent loop
                fi
            done

            # Determine if the interface is using DHCP or static
            if command -v is_dhcp_static &> /dev/null; then
                dhcp=$(is_dhcp_static "${iface}")
            else
                dhcp="unknown" # Fallback if is_dhcp_static is not defined
            fi

            # Append result (color variables should be defined elsewhere in the script)
            result+="${light_blue}${iface}${yellow}(${dhcp})${white}:${blue}${ip}${white}, "
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

    # ----------------------------------------------------------------------
    # get_external_ip
    # ----------------------------------------------------------------------
    # - Checks if a cached IP (in /tmp/external_ip.cache) is still fresh (< 10 mins).
    # - If fresh and valid, reuses it.
    # - Otherwise tries to fetch a new IP from ifconfig.me using curl or wget.
    # - Exports the IP to PROMPT_EXTERNAL_IP and prints it to stdout on success.
    # - Returns non-zero on any failure or invalid IP.
    # ----------------------------------------------------------------------
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
