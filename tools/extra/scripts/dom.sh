#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# DigitalOcean Droplet Manager
#==============================
# Provides an interactive menu using `fzf` to:
# 1. Create a new DigitalOcean droplet.
# 2. List and SSH into an existing droplet.
# 3. Delete/Destroy a droplet.
#————————————————————
# Requirements:
# - `doctl` must be installed and authenticated.
# - `fzf` must be installed.
###############################################################################

# Guard to prevent multiple sourcing
if [[ -z "${DIGITAL_OCEAN_LOADED:-}" ]]; then
    declare -g DIGITAL_OCEAN_LOADED=true

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

    function _display_menu() {
        local title="$1"
        shift
        local options=("$@")

        if [[ ${#options[@]} -eq 0 ]]; then
            echo "[INFO] No options available for ${title}. Returning to the previous menu."
            return 1
        fi

        local menu_items=("0) Back/Exit")
        for ((i = 0; i < ${#options[@]}; i++)); do
            menu_items+=("$((i + 1))) ${options[i]}")
        done

        local choice
        choice=$(printf "%s\n" "${menu_items[@]}" | fzf --prompt "${title} > " || echo "0) Back/Exit")

        if [[ "${choice}" == "0) Back/Exit" || -z "${choice}" ]]; then
            return 1
        fi

        choice=$(echo "${choice}" | sed 's/^[[:space:]]*[0-9]*)[[:space:]]*//' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')

        # Return the selected choice
        echo "${choice}"
        return 0
    }

    function create_droplet() {
        local region os os_version size ssh_key droplet_name
        local regions=() oses=() sizes=() ssh_keys=()

        mapfile -t regions < <(doctl compute region list --format Slug | tail -n +2 | sort -u -V) || {
            echo "[ERROR] Failed to fetch regions."
            return 1
        }

        mapfile -t oses < <(doctl compute image list --public --format Distribution | tail -n +2 | sort -u -V) || {
            echo "[ERROR] Failed to fetch OS distributions."
            return 1
        }

        mapfile -t sizes < <(doctl compute size list --format Slug,Memory,VCPUs,PriceMonthly | grep -E "^s-[12]vcpu" | grep -E -v "\-[intel|amd]" | sort -u -k 4 -V) || {
            echo "[ERROR] Failed to fetch droplet sizes."
            return 1
        }

        mapfile -t ssh_keys < <(doctl compute ssh-key list --format Name,ID | tail -n +2 | sort -u -V) || {
            echo "[ERROR] Failed to fetch SSH keys."
            return 1
        }

        region=$(_display_menu "Select a Region:" "${regions[@]}")
        if [[ $? -ne 0 ]]; then
            return 1
        fi

        os=$(_display_menu "Select an OS:" "${oses[@]}")
        if [[ $? -ne 0 ]]; then
            return 1
        fi

        local versions=()
        mapfile -t versions < <(doctl compute image list --public --format Slug | grep -i "^${os}" | sort -u -V) || {
            echo "[ERROR] Failed to fetch OS versions."
            return 1
        }

        os_version=$(_display_menu "Select an OS Version:" "${versions[@]}")
        if [[ $? -ne 0 ]]; then
            return 1
        fi

        size=$(_display_menu "Select an Image Size:" "${sizes[@]}")
        if [[ $? -ne 0 ]]; then
            return 1
        fi

        size=$(echo "${size}" | awk '{print $1}')

        ssh_key=$(_display_menu "Select an SSH Key:" "${ssh_keys[@]}")
        if [[ $? -ne 0 ]]; then
            return 1
        fi

        ssh_key=$(echo "${ssh_key}" | awk '{print $2}')

        # Loop until a valid droplet name is provided
        while true; do
            read -rp "Enter a name for the droplet: " droplet_name
            if [[ -n "${droplet_name}" && ${#droplet_name} -le 64 ]]; then
                break
            fi
            echo "[ERROR] Droplet name is invalid or too long (max 64 characters). Please try again."
        done

        echo -e "\nSummary:\n    Region:  ${region}\n    OS:      ${os}\n    Version: ${os_version}\n    Size:    ${size}\n    SSH Key: ${ssh_key}\n    Name:    ${droplet_name}\n"
        echo -e "    Cloning: https://github.com/tatanus/BASH.git to /root/BASH\n"

        # Loop until a valid confirmation is provided
        while true; do
            read -rp "Do you want to proceed? (yes/no): " confirmation
            if [[ "${confirmation}" == "yes" ]]; then
                break
            elif [[ "${confirmation}" == "no" ]]; then
                echo "[INFO] Droplet creation canceled."
                return 1
            else
                echo "[ERROR] Invalid input. Please type 'yes' or 'no'."
            fi
        done

        echo "Creating droplet..."
        if ! doctl compute droplet create "${droplet_name}" \
            --region "${region}" \
            --image "${os_version}" \
            --size "${size}" \
            --ssh-keys "${ssh_key}" \
            --wait \
            --format ID,Name,PublicIPv4 \
            --user-data-file dom.yaml \
            --wait; then
            echo "[ERROR] Failed to create droplet."
        else
            echo "[SUCCESS] Droplet created successfully!"
        fi
        _Pause

    }

    function ssh_into_droplet() {
        local droplets=() droplet droplet_ip

        # Fetch the list of droplets
        mapfile -t droplets < <(doctl compute droplet list --format Name,PublicIPv4,Region,Image | tail -n +2 | sort -u -V) || {
            echo "[ERROR] Failed to fetch droplet list."
            return 1
        }

        # Check if there are no droplets
        if [[ ${#droplets[@]} -eq 0 ]]; then
            echo "[INFO] No droplets found. Returning to the previous menu."
            _Pause
            return 1
        fi

        # Display droplets in the menu
        droplet=$(_display_menu "Select a Droplet to SSH into:" "${droplets[@]}")
        if [[ $? -ne 0 ]]; then
            return 1
        fi

        # Extract the public IP address of the selected droplet
        droplet_ip=$(echo "${droplet}" | awk '{print $2}')
        if [[ -z "${droplet_ip}" ]]; then
            echo "[ERROR] Failed to extract IP address from the selected droplet. Returning to the main menu."
            _Pause
            return 1
        fi

        # Attempt to connect via SSH
        echo "Connecting to droplet at ${droplet_ip}..."
        if ! ssh root@"${droplet_ip}"; then
            echo "[ERROR] SSH connection failed. Returning to the main menu."
            _Pause
            return 1
        fi
    }

    function delete_droplet() {
        local droplets=() selection droplet_id droplet_name

        # Fetch the list of droplets with additional details
        mapfile -t droplets < <(doctl compute droplet list --format ID,Name,PublicIPv4,Region,Image | tail -n +2 | sort -u -V) || {
            echo "[ERROR] Failed to fetch droplet list."
            return 1
        }

        # Check if there are no droplets
        if [[ ${#droplets[@]} -eq 0 ]]; then
            echo "[INFO] No droplets found. Returning to the previous menu."
            _Pause
            return 1
        fi

        # Select a droplet to delete
        selection=$(_display_menu "Select a Droplet to DESTROY:" "${droplets[@]}")
        if [[ $? -ne 0 ]]; then
            return 1
        fi

        # Extract the droplet ID and name from the selection
        droplet_id=$(echo "${selection}" | awk '{print $1}')
        droplet_name=$(echo "${selection}" | awk '{print $2}')

        if [[ -z "${droplet_id}" || -z "${droplet_name}" ]]; then
            echo "[ERROR] Failed to parse droplet ID or name from the selection. Returning to the main menu."
            _Pause
            return 1
        fi

        # Loop until valid confirmation is provided
        while true; do
            echo "Are you sure you want to delete '${droplet_name}' (ID: ${droplet_id})? (yes/no)"
            read -r confirmation
            if [[ "${confirmation}" == "yes" ]]; then
                break
            elif [[ "${confirmation}" == "no" ]]; then
                echo "[INFO] Droplet deletion canceled. Returning to the main menu."
                _Pause
                return 1
            else
                echo "[ERROR] Invalid input. Please type 'yes' or 'no'."
            fi
        done

        # Attempt to delete the droplet
        echo "Deleting droplet '${droplet_name}'..."
        if ! doctl compute droplet delete "${droplet_id}" --force; then
            echo "[ERROR] Failed to delete droplet '${droplet_name}'. Returning to the main menu."
            _Pause
            return 1
        fi

        echo "[SUCCESS] Droplet '${droplet_name}' deleted successfully."
        _Pause
    }

    function main_menu() {
        local options=("Create Droplet" "SSH into Droplet" "Destroy Droplet")

        local balance
        balance=$(doctl balance get --format MonthToDateBalance | tail -n +2)

        # Main menu loop
        while true; do
            # Display the menu and get the user's choice
            local choice
            # shellcheck disable=SC2310
            if ! choice=$(_display_menu "Select (\$${balance}):" "${options[@]}"); then
                echo "[INFO] Exiting to the previous menu."
                return 1
            fi

            # Process the user's choice
            case "${choice}" in
                "Create Droplet")
                    # shellcheck disable=SC2310
                    create_droplet || echo "[INFO] Returning to main menu."
                    ;;
                "SSH into Droplet")
                    # shellcheck disable=SC2310
                    ssh_into_droplet || echo "[INFO] Returning to main menu."
                    ;;
                "Destroy Droplet")
                    # shellcheck disable=SC2310
                    delete_droplet || echo "[INFO] Returning to main menu."
                    ;;
                *)
                    echo "[INFO] Invalid option. Please try again."
                    ;;
            esac
        done
    }

    # Dependency Check
    for cmd in doctl fzf; do
        if ! command -v "${cmd}" &> /dev/null; then
            echo "[ERROR] ${cmd} is not installed. Please install it before running this script."
            exit 1
        fi
    done

    # Run the main menu
    main_menu
fi
