#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : ssh_menu.sh
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
if [[ -z "${SSH_FUNCS_LOADED:-}" ]]; then
    declare -g SSH_FUNCS_LOADED=true

    function _Pause() {
        echo
        echo "-----------------------------------"
        read -n 1 -s -r -p "Press any key to continue..."
        echo  # Move to the next line after key press

        # Use ANSI escape codes to move the cursor up and clear lines
        tput cuu 3 # Move the cursor up 3 lines
        tput el   # Clear the current line
        tput el   # Clear the next line
        tput el   # Clear the third line
    }

    # Display menu from a provided list
    # $1: Menu title (unique identifier for the menu)
    # $2: List of options (array or file path)
    # $3: Function to execute on selection
    function _Display_Menu() {
        local title="$1"
        shift
        local action_function="$1"
        shift
        local options=("$@")

        while true; do
            local menu_items=()
            menu_items+=("0) Back/Exit")
            for ((i = 0; i < ${#options[@]}; i++)); do
                # Number each option correctly
                menu_items+=("$((i + 1))) ${options[i]}")
            done

            local choice
            choice=$(printf "%s\n" "${menu_items[@]}" | fzf --prompt "${title} > ")

            # Handle choice
            if [[ -z "${choice}" || "${choice}" == "0) Back/Exit" ]]; then
                return 0
            else
                # This command processes the user's menu choice and extracts the meaningful part:
                # 1. Removes leading numbers and parentheses (e.g., "2) " becomes "").
                # 2. Strips out any trailing "(Last: ...)" text.
                # 3. Removes any extra leading or trailing whitespace.
                # The result is stored in the variable `actual_choice`.
                local actual_choice
                actual_choice=$(echo "${choice}" | sed 's/^[[:space:]]*[0-9]*)[[:space:]]*//' | sed 's/[[:space:]]*(Last:.*)//' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')

                # Perform the action associated with the choice
                "${action_function}" "${actual_choice}"

                _Pause
            fi
        done
    }

    # Path to your SSH config file
    SSH_CONFIG_FILE="${HOME}/.ssh/config"

    # Function to check if the SSH config file exists
    function _Check_SSH_Config() {
        if [[ ! -f "${SSH_CONFIG_FILE}" ]]; then
            echo "Error: SSH config file ${SSH_CONFIG_FILE} does not exist."
            exit 1
        fi
    }

    # function _Process_SSH_Hosts_Menu() {
    #     local choice="$1"

    #     # Check if a function name was provided
    #     if [[ -z "${choice}" ]]; then
    #         warn "Usage: _Process_SSH_Hosts_Menu '<host>'"
    #         return "${_FAIL}"
    #     fi

    #     echo "SSHing to [${choice}]"
    #     ssh -tt "${choice}"
    # }
    function _Process_SSH_Hosts_Menu() {
        local choice="$1"

        if [[ -z "${choice}" ]]; then
            echo "[ERROR] Usage: _Process_SSH_Hosts_Menu '<host>'"
            return 1
        fi

        echo "[INFO] Attempting SSH to [${choice}]..."

        # Retrieve SSH config details
        local CONFIG_BLOCK HOSTNAME PORT PROXYJUMP
        CONFIG_BLOCK=$(awk "/^Host ${choice}\$/,/^Host /" ~/.ssh/config)

        if [[ -z "${CONFIG_BLOCK}" ]]; then
            echo "[ERROR] Host '${choice}' not found in ~/.ssh/config."
            return 1
        fi

        HOSTNAME=$(echo "${CONFIG_BLOCK}" | awk '/^[[:space:]]*Hostname/{print $2; exit}')
        PORT=$(echo "${CONFIG_BLOCK}" | awk '/^[[:space:]]*Port/{print $2; exit}')
        PROXYJUMP=$(echo "${CONFIG_BLOCK}" | awk '/^[[:space:]]*ProxyJump/{print $2; exit}')

        HOSTNAME=${HOSTNAME:-localhost}
        PORT=${PORT:-22}

        # Connectivity check function with verbose error capturing
        function _ssh_test() {
            local host_alias="$1"
            local output
            output=$(ssh -o BatchMode=yes -o ConnectTimeout=5 -vvv "${host_alias}" exit 2>&1)
            local status=$?

            if [[ ${status} -ne 0 ]]; then
                echo "[ERROR] SSH test failed for [${host_alias}]:"
                if echo "${output}" | grep -q "Connection refused"; then
                    echo "    - Connection refused: Verify SSH is running and accessible."
                elif echo "${output}" | grep -q "Permission denied"; then
                    echo "    - Permission denied: SSH key missing or invalid credentials."
                elif echo "${output}" | grep -q "Could not resolve hostname"; then
                    echo "    - DNS resolution failed: Check host entry or network connectivity."
                elif echo "${output}" | grep -q "No route to host"; then
                    echo "    - No route to host: Network issue or firewall blocking."
                elif echo "${output}" | grep -q "Connection timed out"; then
                    echo "    - Connection timed out: Host unreachable or firewall issue."
                elif echo "${output}" | grep -q "Stdio forwarding request failed"; then
                    echo "    - Stdio forwarding request failed: SSH forwarding or ProxyJump misconfiguration."
                else
                    echo "    - Unrecognized error:"
                    echo "---------------- DEBUG OUTPUT ----------------"
                    echo "${output}" | tail -n 20
                    echo "----------------------------------------------"
                fi
            fi

            return "${status}"
        }

        # Check ProxyJump host first, if applicable
        if [[ -n "${PROXYJUMP}" ]]; then
            echo "[INFO] Checking ProxyJump host [${PROXYJUMP}]..."
            if ! _ssh_test "${PROXYJUMP}"; then
                echo "[FAIL] ProxyJump host check failed. Aborting connection."
                return 1
            fi
            echo "[PASS] ProxyJump host [${PROXYJUMP}] reachable."
        fi

        # Check final target host
        echo "[INFO] Checking final target host [${choice}] with current SSH key..."
        ssh_output=$(ssh -o BatchMode=yes -o ConnectTimeout=5 -vvv "${choice}" exit 2>&1)
        ssh_status=$?

        if [[ ${ssh_status} -ne 0 ]]; then
            echo "[ERROR] SSH test failed for [${choice}]:"
            if echo "${ssh_output}" | grep -q "Permission denied"; then
                echo "  - Authentication failed (Permission denied):"
                echo "    The SSH key is missing, not authorized, or invalid credentials were provided."
                echo "[ACTION] Attempting to upload your SSH public key."

                # Attempt key upload
                ssh_copy_output=$(ssh-copy-id -i ~/.ssh/id_rsa.pub "${choice}" 2>&1)
                ssh_copy_status=$?

                if [[ ${ssh_copy_status} -ne 0 ]]; then
                    echo "[ERROR] ssh-copy-id failed to upload key to [${choice}]:"
                    echo "${ssh_copy_output}" | tail -n 10
                    echo "[ACTION] Verify remote credentials or SSH configuration."
                    return 1
                fi

                # Retest SSH connection after key upload
                if ! ssh -o BatchMode=yes -o ConnectTimeout=5 "${choice}" exit &> /dev/null; then
                    echo "[ERROR] SSH still failing after key upload. Possible remote config issue."
                    return 1
                fi

                echo "[PASS] SSH key successfully uploaded. Connection verified."

            elif echo "${ssh_output}" | grep -q "Stdio forwarding request failed"; then
                echo "  - ProxyJump failed (stdio forwarding request rejected):"
                echo "    The jump host (${PROXYJUMP:-unspecified}) is refusing to forward SSH traffic."
                echo "[ACTION] Verify the ProxyJump host configuration and ensure port forwarding (AllowTcpForwarding) is enabled on the jump host."
                return 1

            elif echo "${ssh_output}" | grep -q "Connection refused"; then
                echo "  - Connection refused by remote host:"
                echo "    SSH service may be stopped, blocked by a firewall, or running on a different port."
                echo "[ACTION] Verify the remote SSH service is active and reachable, and confirm the SSH port number."
                return 1

            elif echo "${ssh_output}" | grep -q "No route to host"; then
                echo "  - Network unreachable (No route to host):"
                echo "    Your local system or network can't reach the target host due to routing issues or firewalls."
                echo "[ACTION] Check network connectivity, firewall settings, and routing."
                return 1

            elif echo "${ssh_output}" | grep -q "Could not resolve hostname"; then
                echo "  - Hostname resolution failed:"
                echo "    The specified hostname '${HOSTNAME}' can't be resolved to an IP address."
                echo "[ACTION] Check the hostname in your SSH configuration or DNS settings."
                return 1

            elif echo "${ssh_output}" | grep -q "Connection timed out"; then
                echo "  - Connection attempt timed out:"
                echo "    The remote system may be offline, firewalled, or experiencing network issues."
                echo "[ACTION] Verify network connectivity and confirm the host is online and reachable."
                return 1

            elif echo "${ssh_output}" | grep -q "Connection reset by peer"; then
                echo "  - Connection reset by remote host:"
                echo "    The SSH connection was unexpectedly closed, possibly due to remote SSH misconfiguration or security restrictions."
                echo "[ACTION] Review SSH logs on the remote host or check security/firewall policies."
                return 1

            elif echo "${ssh_output}" | grep -q "Host key verification failed"; then
                echo "  - Host key mismatch detected:"
                echo "    The remote host key has changed or does not match what's in your known_hosts file."
                echo "[ACTION] Verify that the remote system hasn't been replaced or compromised. Consider updating your known_hosts file."
                return 1

            else
                echo "  - Unidentified SSH error encountered:"
                echo "${ssh_output}" | tail -n 15
                echo "[ACTION] Review the detailed SSH debug output above to identify and resolve the issue."
                return 1

            fi
        else
            echo "[PASS] SSH connection verified with existing key."
        fi

        # Proceed with SSH
        ssh -tt "${choice}"
    }

    # Function to add a new TAP_* host entry to the config file
    function _Add_New_SSH_Host() {
        # Prompt user for new host details
        echo "Enter new TAP_* host details."

        # Read inputs safely and validate them
        read -r -p "Host name (e.g., TAP_100): " host_name
        if [[ -z "${host_name}" || ! "${host_name}" =~ ^TAP_ ]]; then
            echo "Error: Host name must start with 'TAP_' and cannot be empty."
            return
        fi

        read -r -p "ProxyJump server (e.g., jump1, jump2): " proxy_jump
        if [[ -z "${proxy_jump}" ]]; then
            echo "Error: ProxyJump server cannot be empty."
            return
        fi

        read -r -p "Port (e.g., 10000): " port
        if ! [[ "${port}" =~ ^[0-9]+$ ]]; then
            echo "Error: Port must be a valid number."
            return
        fi

        # Validate input formatting and ensure required fields are not empty
        if [[ -z "${host_name}" || -z "${proxy_jump}" || -z "${port}" ]]; then
            echo "Error: All fields are required."
            return
        fi

        # Generate the LocalCommand dynamically
        local local_command="umount -u /Users/pentest/mnt/${proxy_jump} 2>/dev/null || true && mkdir -p /Users/pentest/mnt/${host_name} && sshfs -o IdentityFile=~/.ssh/id_rsa -o ProxyJump=${proxy_jump} root@localhost:/ /Users/pentest/mnt/${host_name} -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3"

        # Format the new host entry
        local new_entry
        new_entry=$(
                cat << EOF

Host ${host_name}
    Hostname localhost
    ProxyJump ${proxy_jump}
    Port ${port}
    #LocalCommand ${local_command}
EOF
        )

        # Append the new entry to the SSH config file
        echo -e "${new_entry}" >> "${SSH_CONFIG_FILE}"

        # Inform the user of success
        echo "New host entry for ${host_name} added to ${SSH_CONFIG_FILE}."
    }

    function _Process_SSH_Menu() {
        local choice="$1"

        # Validate input
        if [[ -z "${choice}" ]]; then
            warn "Usage: _Process_SSH_Menu 'option'"
            return "${_FAIL}"
        fi

        # Process choices
        if [[ "${choice}" == "SSH to host" ]]; then
            # Safely populate the SSH_HOSTS array using mapfile
            mapfile -t SSH_HOSTS < <(awk '/^Host / && !/\*/ {print $2}' "${SSH_CONFIG_FILE}")
            _Display_Menu "SSH hosts" "_Process_SSH_Hosts_Menu" "${SSH_HOSTS[@]}"
        elif [[ "${choice}" == "Add new SSH host" ]]; then
            _Add_New_SSH_Host
        fi
    }

    # Main menu function
    function _Main_SSH_Menu() {
        # Array for SSH tasks
        SETUP_MENU_ITEMS=(
            "SSH to host"
            "Add new SSH host"
        )
        _Display_Menu "SSH_MENU" "_Process_SSH_Menu" "${SETUP_MENU_ITEMS[@]}"
    }

    # "Main" function
    function ssh_menu() {
        # Run the main menu
        _Check_SSH_Config # Ensure the config file exists
        _Main_SSH_Menu
    }

    ssh_menu
fi
