#!/usr/bin/env bash

# =============================================================================
# NAME        : ssh_funcs.sh
# DESCRIPTION : 
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-08 19:57:22
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-08 19:57:22  | Adam Compton | Initial creation.
# =============================================================================

## Guard to prevent multiple sourcing
#if [[ -z "${SSH_FUNCS_LOADED:-}" ]]; then
#    declare -g SSH_FUNCS_LOADED=true

    function _Pause() { 
        echo
        echo "-----------------------------------"
        read -n 1 -s -r -p "Press any key to continue..."
        echo  # Move to the next line after key press

        # Use ANSI escape codes to move the cursor up and clear lines
    	tput cuu 3   # Move the cursor up 3 lines
    	tput el      # Clear the current line
    	tput el      # Clear the next line
    	tput el      # Clear the third line
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
            for ((i=0; i<${#options[@]}; i++)); do
                # Number each option correctly
                menu_items+=("$((i+1))) ${options[i]}")
            done

            local choice
            choice=$(printf "%s\n" "${menu_items[@]}" | fzf --prompt "$title > ")

            # Handle choice
            if [[ -z "$choice" || "$choice" == "0) Back/Exit" ]]; then
                return 0
            else
                # This command processes the user's menu choice and extracts the meaningful part:
                # 1. Removes leading numbers and parentheses (e.g., "2) " becomes "").
                # 2. Strips out any trailing "(Last: ...)" text.
                # 3. Removes any extra leading or trailing whitespace.
                # The result is stored in the variable `actual_choice`.
                local actual_choice
                actual_choice=$(echo "$choice" | sed 's/^[[:space:]]*[0-9]*)[[:space:]]*//' | sed 's/[[:space:]]*(Last:.*)//' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')

                # Perform the action associated with the choice
    #            clear
                "$action_function" "$actual_choice"
                
                _Pause
            fi
        done
    }

	# Path to your SSH config file
	#SSH_CONFIG_FILE="$HOME/.ssh/config"
	SSH_CONFIG_FILE="../ssh_config"

	# Function to check if the SSH config file exists
	function _Check_SSH_Config() {
	    if [[ ! -f "$SSH_CONFIG_FILE" ]]; then
	        echo "Error: SSH config file $SSH_CONFIG_FILE does not exist."
	        exit 1
	    fi
	}

	function _Process_SSH_Hosts_Menu() {
        local choice="$1"

        # Check if a function name was provided
        if [[ -z "$choice" ]]; then
            warn "Usage: _Process_SSH_Hosts_Menu '<host>'"
            return $_FAIL
        fi

        echo "SSHing to [${choice}]"
        ssh -tt "$choice"
   	}

	# Function to add a new TAP_* host entry to the config file
	function _Add_New_SSH_Host() {
	    # Prompt user for new host details
	    echo "Enter new TAP_* host details"
	    read -p "Host name (e.g., TAP_XXX): " host_name
	    read -p "ProxyJump server: " proxy_jump
	    read -p "Port: " port

	    # Validate inputs (ensure they are not empty)
	    if [[ -z "$host_name" || -z "$proxy_jump" || -z "$port" ]]; then
	        echo "All fields are required. Aborting."
	        exit 1
	    fi

	    # Validate that the port is a valid number
	    if ! [[ "$port" =~ ^[0-9]+$ ]]; then
	        echo "Error: Port must be a valid number. Aborting."
	        exit 1
	    fi

	    # Validate host_name format (ensure it's in the correct format for a TAP_* host)
	    if ! [[ "$host_name" =~ ^TAP_ ]]; then
	        echo "Error: Host name must start with TAP_. Aborting."
	        exit 1
	    fi

	    # Format the new TAP_* host entry to append to the config file
	    new_entry="\nHost $host_name\n    ProxyJump $proxy_jump\n    Port $port"

	    # Append the new entry to the SSH config file
	    echo -e "$new_entry" >> "$SSH_CONFIG_FILE"
	    echo "New host entry added to $SSH_CONFIG_FILE"
	}

	function _Process_SSH_Menu() {
	    local choice="$1"

    	# Validate input
	    if [[ -z "$choice" ]]; then
        	warn "Usage: _Process_SSH_Menu 'option'"
    	    return $_FAIL
	    fi

	    # Process choices
    	if [ "$choice" == "SSH to host" ]; then
			SSH_HOSTS=($(awk '/^Host / && !/\*/ {print $2}' "${SSH_CONFIG_FILE}"))
	        _Display_Menu "SSH hosts" "_Process_SSH_Hosts_Menu" "${SSH_HOSTS[@]}"
    	elif [ "$choice" == "Add new SSH host" ]; then
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

	# Run the main menu
	_Check_SSH_Config  # Ensure the config file exists
	_Main_SSH_Menu
#fi