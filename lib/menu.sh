#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : menu.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-08 20:11:12
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-08 20:11:12  | Adam Compton | Initial creation.
# =============================================================================

# Guard to prevent multiple sourcing
if [[ -z "${MENU_SH_LOADED:-}" ]]; then
    declare -g MENU_SH_LOADED=true

    # Path to persistent menu timestamps
    MENU_TIMESTAMP_FILE="${PENTEST_DIR}/menu_timestamps"

    # Ensure the timestamp file exists
    if [[ ! -f "${MENU_TIMESTAMP_FILE}" ]]; then
        touch "${MENU_TIMESTAMP_FILE}" || {
            fail "Failed to create file: ${MENU_TIMESTAMP_FILE}"
            exit 1
        }
        info "Created file: ${MENU_TIMESTAMP_FILE}"
    fi

    # Append timestamps to each option
    # $1: Menu title
    # Remaining arguments: List of options
    function _Append_Timestamps_To_Options() {
        local title="$1"
        shift
        local options=("$@")
        local updated_options=()

        for option in "${options[@]}"; do
            if [[ -n "${option}" ]]; then
                local timestamp
                # Check if the entry exists in the timestamp file
                timestamp=$(grep "^${title}::${option}:" "${MENU_TIMESTAMP_FILE}" | cut -d':' -f4-)
                if [[ -n "${timestamp}" ]]; then
                    # Append the option and timestamp into two columns
                    updated_options+=("$(printf '%-30s %s' "${option}" "(Last: ${timestamp})")")
                else
                    # Append only the option if no timestamp exists
                    updated_options+=("$(printf '%-30s %s' "${option}" "")")
                fi
            fi
        done

        # Print each option on a new line
        printf "%s\n" "${updated_options[@]}"
    }

    # Update the timestamp of a selected menu item
    # $1: Menu title
    # $2: Selected item
    function _Update_Menu_Timestamp() {
        local menu_title="$1"
        local selected_item="$2"
        local timestamp
        timestamp=$(date +"%Y-%m-%d %H:%M:%S")

        # Check if the file exists, create it if it doesn't
        if [[ ! -f "${MENU_TIMESTAMP_FILE}" ]]; then
            touch "${MENU_TIMESTAMP_FILE}"
        fi

        # Check for macOS or Ubuntu
        if sed --version > /dev/null 2>&1; then
            # GNU sed (Ubuntu)
            if grep -q "^${menu_title}::${selected_item}:" "${MENU_TIMESTAMP_FILE}"; then
                # If the entry exists, replace it
                sed -i "/^${menu_title}::${selected_item}:/d" "${MENU_TIMESTAMP_FILE}"
            fi
        else
            # BSD sed (macOS)
            if grep -q "^${menu_title}::${selected_item}:" "${MENU_TIMESTAMP_FILE}"; then
                # If the entry exists, replace it
                sed -i '' "/^${menu_title}::${selected_item}:/d" "${MENU_TIMESTAMP_FILE}"
            fi
        fi

        # Add the new entry (append or replace)
        echo "${menu_title}::${selected_item}:${timestamp}" >> "${MENU_TIMESTAMP_FILE}"
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
            # Append timestamps to each option
            local updated_options=()
            while IFS= read -r line; do
                updated_options+=("${line}")
            done < <(_Append_Timestamps_To_Options "${title}" "${options[@]}")

            local menu_items=()
            menu_items+=("0) Back/Exit")
            for ((i = 0; i < ${#updated_options[@]}; i++)); do
                # Number each option correctly
                menu_items+=("$((i + 1))) ${updated_options[i]}")
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

                # Update menu item timestamp persistently
                _Update_Menu_Timestamp "${title}" "${actual_choice}"

                # Perform the action associated with the choice
                "${action_function}" "${actual_choice}"

                _Pause
            fi
        done
    }

    # Perform an action based on menu selection
    # $1: Selected menu item
    function _Perform_Menu_Action() {
        local choice="$1"

        # Example: Placeholder for specific actions
        info "Action performed for: ${choice}"
        log_command "Executed action for menu item: ${choice}"
    }

    # Function to execute a Bash command or a script from $SCRIPT_DIR/modules/
    function _Execute_And_Wait() {
        local input="$1"

        if [[ -z "${input}" ]]; then
            warning "Usage: execute_command_or_script '<command or script>'"
            return "${_FAIL}"
        fi

        # Check if the input is a script in $SCRIPT_DIR/modules
        local script_path="${SCRIPT_DIR}/modules/${input}"

        # validate $script_path exists and is executable
        if [[ -x "${script_path}" ]]; then
            info "Executing script: ${script_path}"
            "${script_path}"
        else
            # Assume it's a command and try to execute it
            info "Executing command: ${input}"
            eval "${input}"
        fi

        # Capture the exit status
        local exit_status=$?

        if [[ ${exit_status} -eq 0 ]]; then
            info "Execution completed successfully."
        else
            info "Execution failed with exit status ${exit_status}."
        fi

        return "${exit_status}"
    }

    # Function to wait for a given process to end
    function _Wait_Pid() {
        # Capture the process ID of the most recently executed background command
        process_id=$!

        # Check if the process ID is valid (non-empty and numeric)
        if [[ -z "${process_id}" || ! "${process_id}" =~ ^[0-9]+$ ]]; then
            #info "Error: Invalid process ID."
            return "${_FAIL}"  # Return an error code
        fi

        # Wait for the process with the captured PID to complete
        wait "${process_id}"
        wait_status=$?  # Capture the exit status of the wait command

        # Check if the wait command was successful
        if [[ ${wait_status} -ne 0 ]]; then
            fail "Error: Process with PID ${process_id} did not complete successfully."
            return "${_FAIL}"  # Return an error code
        fi

        # Get the sleep duration from the argument, default to 0.5 second if not provided
        sleep_duration="${1:-0.5}"

        # Introduce the specified delay after the process completes
        sleep "${sleep_duration}"

        return "${_PASS}"  # Return success
    }

    function _Exec_Function() {
        local function_name="$1"  # Use a descriptive variable name

        # Check if a function name was provided
        if [[ -z "${function_name}" ]]; then
            warn "Usage: _Exec_Function '<function_name>'"
            return "${_FAIL}"
        fi

        # Check if the function is defined
        if declare -f "${function_name}" > /dev/null; then
            info "Calling function: ${function_name}"
            "${function_name}" || {
                fail "Execution of function ${function_name} failed."
            }
        else
            fail "Function ${function_name} not found."
        fi
    }
fi
