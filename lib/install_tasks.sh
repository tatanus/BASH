#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : install_tasks.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-10 12:29:41
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-10 12:29:41  | Adam Compton | Initial creation.
# =============================================================================

# Guard to prevent multiple sourcing
if [[ -z "${INSTALL_TASKS_SH_LOADED:-}" ]]; then
    declare -g INSTALL_TASKS_LOADED=true

    # -----------------------------------------------------------------------------
    # ---------------------------------- Install Specific Tools -------------------
    # -----------------------------------------------------------------------------

    # Function to install Impacket
    # This function installs Python dependencies for the Impacket tool.
    function Install_Impacket() {
        _Pushd "${TOOLS_DIR}/impacket"

        if _Pip_Install "."; then
            pass "Installed pip packages for impacket."
        else
            fail "Failed to install pip packages for impacket."
        fi
        _Popd
    }

    # Function to move in-house tools
    # This function moves and sets up various custom tools into the appropriate directories.
    function _Install_Inhouse_Tools() {
        # Ensure the source directory exists
        if [[ ! -d "${SCRIPT_DIR}/tools/extra" ]]; then
            fail "Directory [${SCRIPT_DIR}/tools/extra] does not exist."
            return "${_FAIL}"
        fi

        # Source the bash.funcs.sh script if it exists
        [[ -f "${SCRIPT_DIR}/tools/extra/inhouse.sh" ]] && source "${SCRIPT_DIR}/tools/extra/inhouse.sh"
    }

    function _Install_All_Tools() {
        TOOL_MENU_ITEMS=()
        MODULES_DIR="tools/modules"

        # ------------------------------------------------------------------------------
        # Step 1: Dynamically populate TOOL_MENU_ITEMS with script basenames
        # ------------------------------------------------------------------------------
        if [[ -d "${MODULES_DIR}" ]]; then
            for script in "${MODULES_DIR}"/*.sh; do
                # Skip if the directory is empty and returns "*.sh"
                [[ -f "${script}" ]] || continue

                tool_name="$(basename "${script}" .sh)" # e.g., "mytool" from "mytool.sh"
                TOOL_MENU_ITEMS+=("${tool_name}")
            done
        else
            warn "Directory not found: ${MODULES_DIR}"
        fi

        # ------------------------------------------------------------------------------
        # Step 2: Call each item in INSTALL_TOOLS_MENU_ITEMS
        # ------------------------------------------------------------------------------
        for item in "${INSTALL_TOOLS_MENU_ITEMS[@]}"; do
            # Skip this function
            if [[ "${item}" == "_Install_All_Tools" ]]; then
                continue
            fi

            info "Executing predefined installation function: ${item}"
            # This presumably calls a bash function named "${item}"
            if ! _Exec_Function "${item}"; then
                fail "Failed to execute predefined installation function: ${item}"
            fi

            # Update menu item timestamp persistently
            _Update_Menu_Timestamp "TOOL INSTALLATION MENU" "${item}"
        done

        # ------------------------------------------------------------------------------
        # Step 3: Install impacket
        # ------------------------------------------------------------------------------
        script_file="impacket"
        info "Found script for tool: ${script_file}"

        # Construct the full path to the script
        local script_path="${MODULES_DIR}/${script_file}.sh"

        if [[ ! -f "${script_path}" ]]; then
            fail "Script file not found: ${script_path}"
            # shellcheck disable=SC2104
            continue
        fi

        # Source the script so we can access its functions
        if ! source "${script_path}"; then
            fail "Failed to source script: ${script_path}"
            # shellcheck disable=SC2104
            continue
        fi

        # Build the install function name, e.g. "install_mytool"
        # Build the test and install function names
        local install_function="install_${script_file}"
        local test_function="test_${script_file}"

        # Check if the test function is defined and run it
        if declare -f "${test_function}" > /dev/null; then
            if "${test_function}"; then
                info "Tool ${script_file} is already installed. Skipping."
            else
                # Install the tool if the test fails
                info "Installing tool: ${install_function}"
                if declare -f "${install_function}" > /dev/null; then
                    if ! "${install_function}"; then
                        fail "Installation failed for tool: ${script_file}"
                    else
                        pass "Successfully installed: ${script_file}"

                        # Update menu item timestamp persistently
                        _Update_Menu_Timestamp "TOOL INSTALLATION MENU" "${script_file}"
                    fi
                else
                    fail "Installation function not found: ${install_function}"
                fi
            fi
        else
            warn "Test function not found: ${test_function}. Skipping test."
        fi

        # ------------------------------------------------------------------------------
        # Step 4: For each script in TOOL_MENU_ITEMS, source it and call install_<tool>
        # ------------------------------------------------------------------------------
        for script_file in "${TOOL_MENU_ITEMS[@]}"; do

            # Update menu item timestamp persistently
            _Update_Menu_Timestamp "TOOL INSTALLATION MENU" "${script_file}"

            # Check if the script_file is "impacket" and skip if it is
            if [[ "${script_file}" == "impacket" ]]; then
                continue
            fi

            info "Found script for tool: ${script_file}"

            # Construct the full path to the script
            local script_path="${MODULES_DIR}/${script_file}.sh"

            if [[ ! -f "${script_path}" ]]; then
                fail "Script file not found: ${script_path}"
                continue
            fi

            # Source the script so we can access its functions
            if ! source "${script_path}"; then
                fail "Failed to source script: ${script_path}"
                continue
            fi

            # Build the install function name, e.g. "install_mytool"
            # Build the test and install function names
            local install_function="install_${script_file}"
            local test_function="test_${script_file}"

            # Check if the test function is defined and run it
            if declare -f "${test_function}" > /dev/null; then
                if "${test_function}"; then
                    info "Tool ${script_file} is already installed. Skipping."
                else
                    # Install the tool if the test fails
                    info "Installing tool: ${install_function}"
                    if declare -f "${install_function}" > /dev/null; then
                        if ! "${install_function}"; then
                            fail "Installation failed for tool: ${script_file}"
                        else
                            pass "Successfully installed: ${script_file}"
                        fi
                    else
                        fail "Installation function not found: ${install_function}"
                    fi
                fi
            else
                warn "Test function not found: ${test_function}. Skipping test."
            fi

            # Update menu item timestamp persistently
            _Update_Menu_Timestamp "TOOL INSTALLATION MENU" "${script_file}"

        done

        # If you want a final success message (assuming non-critical failures are okay)
        pass "All installation tasks completed."
    }
fi
