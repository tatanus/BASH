#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : menu_tasks.sh
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
if [[ -z "${MENU_TASKS_SH_LOADED:-}" ]]; then
    declare -g MENU_TASKS_LOADED=true

    # -----------------------------------------------------------------------------
    # ---------------------------------- Menus ------------------------------------
    # -----------------------------------------------------------------------------

    # Function to process configuration menu choices
    # $1: The user's choice from the configuration menu
    function _Process_Config_Menu() {
        local choice="$1"

        case "${choice}" in
            "Edit config.sh")
                _Edit_And_Reload_File "${CONFIG_FILE}"
                ;;
            "Edit pentest.env")
                # shellcheck disable=SC2153
                _Edit_And_Reload_File "${ENV_FILE}"
                ;;
            "Edit pentest.keys")
                _Edit_And_Reload_File "${KEYS_FILE}"
                ;;
            "Edit pentest.alias")
                _Edit_And_Reload_File "${ALIAS_FILE}"
                ;;
            *)
                warn "Invalid option: ${choice}" # Log warning for invalid options
                ;;
        esac
    }

    # Function to open a file in an editor and reload it
    # $1: File path to edit and reload
    function _Edit_And_Reload_File() {
        local file="$1"

        # Check if the file exists
        if [[ ! -f "${file}" ]]; then
            warn "File not found: ${file}"
            return "${_FAIL}"
        fi

        # Open the file in the user's preferred editor, defaulting to nano
        local editor="${EDITOR:-nano}" # Use $EDITOR if set, otherwise nano
        if ! ${editor} "${file}"; then
            warn "Failed to open ${file} in editor."
            return "${_FAIL}"
        fi

        # Reload the file after editing
        if ! source "${file}"; then
            warn "Failed to source ${file} after editing."
            return "${_FAIL}"
        fi

        pass "Reloaded configuration from ${file}."
    }

    # Function to process tool installation menu choices
    # $1: The user's choice from the tool installation menu
    function _Process_Tool_Install_Menu() {
        local choice="$1"

        # Validate input
        if [[ -z "${choice}" ]]; then
            warn "Usage: _Process_Tool_Install_Menu 'option'"
            return "${_FAIL}"
        fi

        # Check if the choice matches a predefined menu item
        found_match=false
        for item in "${INSTALL_TOOLS_MENU_ITEMS[@]}"; do
            if [[ "${item}" == "${choice}" ]]; then
                found_match=true
                info "Executing predefined installation function: ${choice}"

                # Check if the item is "_Install_All_Tools"
                if [[ "${choice}" == "_Install_All_Tools" ]]; then
                    # Pass TOOL_MENU_ITEMS[@] as arguments
                    if ! _Exec_Function "${choice}" "${TOOL_MENU_ITEMS[@]}"; then
                        fail "Failed to execute predefined installation function: ${choice} with TOOL_MENU_ITEMS."
                        return "${_FAIL}"
                    fi
                else
                    # Execute the function without additional arguments
                    if ! _Exec_Function "${choice}"; then
                        fail "Failed to execute predefined installation function: ${choice}"
                        return "${_FAIL}"
                    fi
                fi

                break
            fi
        done

        if [[ "${found_match}" == false ]]; then
            # Define modules directory
            local MODULES_DIR="${SCRIPT_DIR}/tools/modules"
            local script_file="${MODULES_DIR}/${choice}.sh"

            # Check if the script file exists
            if [[ -f "${script_file}" ]]; then
                if ! _Install_Tool "${script_file}"; then
                    fail "Failed to install tool: ${script_file}. Moving to the next tool."
                fi
            else
                fail "Script file not found: ${script_file}"
                return "${_FAIL}"
            fi
        fi

        # Success message if no errors occurred
        pass "Tool installation for '${choice}' completed successfully."
        return "${_PASS}"
    }

    # function _Process_Tools_Category_Install_Menu() {
    #     local choice="$1"

    #     # Validate input
    #     if [[ -z "${choice}" ]]; then
    #         warn "Usage: _Process_Tools_Category_Install_Menu 'option'"
    #         return "${_FAIL}"
    #     fi

    #     info "Executing function: ${choice}"
    #     if ! _Process_Tool_Install_Menu "${choice}"; then
    #         fail "Failed to install: ${choice}"
    #         return "${_FAIL}"
    #     fi
    # }

    # function _Process_Tools_Categories_Install_Menu() {
    #     local choice="$1"

    #     # Validate input
    #     if [[ -z "${choice}" ]]; then
    #         warn "Usage: _Process_Tools_Categories_Install_Menu 'option'"
    #         return "${_FAIL}"
    #     fi

    #     if [[ "${choice}" == "ALL" ]]; then
    #         # List all modules regardless of category
    #         local all_modules=("${!tool_categories[@]}")

    #         # Sort the category_modules array alphabetically
    #         IFS=$'\n' all_modules=($(sort <<< "${all_modules[*]}"))
    #         unset IFS

    #         _Display_Menu "${choice} Tasks" "_Process_Tools_Category_Install_Menu" true "${all_modules[@]}"
    #     else
    #         # List modules specific to the selected category
    #         local category_modules=()
    #         for script in "${!tool_categories[@]}"; do
    #             if [[ " ${tool_categories[${script}]} " == *" ${choice} "* ]]; then
    #                 category_modules+=("${script}")
    #             fi
    #         done

    #         # Sort the category_modules array alphabetically
    #         IFS=$'\n' category_modules=($(sort <<< "${category_modules[*]}"))
    #         unset IFS

    #         _Display_Menu "${choice} Tasks" "_Process_Tools_Category_Install_Menu" true "${category_modules[@]}"
    #     fi
    # }

    # Function to process start menu choices
    # $1: The user's choice from the start menu
    function _Process_Start_Menu() {
        local choice="$1"

        # Validate input
        if [[ -z "${choice}" ]]; then
            warn "Usage: _Process_Start_Menu 'option'"
            return "${_FAIL}"
        fi

        # Process choices
        if [[ "${choice}" == "Setup BASH Environment" ]]; then
            _Display_Menu "Setup BASH Environment" "_Exec_Function" true "${BASH_ENVIRONMENT_MENU_ITEMS[@]}"
        elif [[ "${choice}" == "Setup PENTEST Environment" ]]; then
            _Display_Menu "Setup PENTEST Environment" "_Exec_Function" true "${PENTEST_ENVIRONMENT_MENU_ITEMS[@]}"
        elif [[ "${choice}" == "Edit Config Files" ]]; then
            _Display_Menu "Configuration Menu" "_Process_Config_Menu" false "${CONFIG_MENU_ITEMS[@]}"
        elif [[ "${choice}" == "Install Tools" ]]; then
            TOOL_MENU_ITEMS=("${INSTALL_TOOLS_MENU_ITEMS[@]}")
            MODULES_DIR="tools/modules"

            # Dynamically add tool names from scripts in MODULES_DIR
            if [[ -d "${MODULES_DIR}" ]]; then
                for script in "${MODULES_DIR}"/*.sh; do
                    if [[ -f "${script}" ]]; then
                        tool_name=$(basename "${script}" .sh) # Extract the tool name
                        TOOL_MENU_ITEMS+=("${tool_name}")
                    fi
                done
            else
                warn "Directory not found: ${MODULES_DIR}"
            fi

            _Display_Menu "TOOL INSTALLATION MENU" "_Process_Tool_Install_Menu" true "${TOOL_MENU_ITEMS[@]}"
        # elif [[ "${choice}" == "Install Tools Categories" ]]; then
        #     TOOL_MENU_ITEMS=("${INSTALL_TOOLS_MENU_ITEMS[@]}")
        #     MODULES_DIR="tools/modules"

        #     # Dynamically add tool names from scripts in MODULES_DIR
        #     if [[ -d "${MODULES_DIR}" ]]; then
        #         for script in "${MODULES_DIR}"/*.sh; do
        #             if [[ -f "${script}" ]]; then
        #                 tool_name=$(basename "${script}" .sh) # Extract the tool name
        #                 TOOL_MENU_ITEMS+=("${tool_name}")
        #                 source "${script}"
        #             fi
        #         done
        #     else
        #         warn "Directory not found: ${MODULES_DIR}"
        #     fi

        #     _Display_Menu "CHOOSE A TOOL CATEGORY" "_Process_Tools_Categories_Install_Menu" false "${TOOL_CATEGORIES[@]}"
        elif [[ "${choice}" == "Test Tool Installs" ]]; then
            _Test_Tool_Installs
        elif [[ "${choice}" == "Pentest Menu" ]]; then
            source "${SCRIPT_DIR}/pentest_menu/pentest_menu.sh"
            _Pentest_Menu
        else
            warn "Invalid option: ${choice}" # Log warning for invalid start menu option
        fi
    }
fi
