#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : SetupBashAuto.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-16 16:51:35
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-16 16:51:35  | Adam Compton | Initial creation.
# =============================================================================

# Minimal placeholders (until more robust functions can be defined later)
function fail() {
    echo "[- FAIL  ] $*" >&2
}
function pass() {
    echo "[+ PASS  ] $*"
}
function info() {
    echo "[* INFO  ] $*"
}
function warn() {
    echo "[! WARN  ] $*"
}

# Initialize the error flag
ERROR_FLAG=false

# Ensure the script is being run under Bash
if [[ -z "${BASH_VERSION:-}" ]]; then
    fail "Error: This script must be run under Bash."
    ERROR_FLAG=true
fi

# Ensure Bash version is 4.0 or higher
if [[ -n "${BASH_VERSION:-}" && "${BASH_VERSINFO[0]}" -lt 4 ]]; then
    fail "Error: This script requires Bash version 4.0 or higher. Current version: ${BASH_VERSION}"
    ERROR_FLAG=true
fi

# Ensure the script is run as root (user ID 0)
if [[ ${EUID} -ne 0 ]]; then
    fail "Error: This script must be run as root."
    ERROR_FLAG=true
fi

# If any errors occurred, display a summary and exit
if ${ERROR_FLAG}; then
    echo
    fail "--------------------------------------------------"
    fail "One or more errors occurred:"
    fail "  - Ensure you are using Bash version 4.0 or higher."
    fail "  - Ensure you are running this script as root as"
    fail "    some tools will need to be installed and other"
    fail "    'root' tasks will possibly be performed"
    fail
    fail "-----------------------------------"
    if [[ -t 0 ]]; then  # check if running interactively
        read -n 1 -s -r -p "Press any key to continue..."
        echo
    fi
    echo  # Move to the next line after key press
    #exit 1  # Exit with a failure status code
fi

# Success message if no errors
pass "All checks passed. Continuing script execution."

# -----------------------------------------------------------------------------
# ---------------------------------- IMPORTS/SOURCES --------------------------
# -----------------------------------------------------------------------------

# Check if the HOME environment variable is set
if [[ -n "${HOME}" ]]; then
    # If HOME is set, use it
    info "HOME environment variable is set. Using HOME: ${HOME}"
elif command -v getent > /dev/null 2>&1; then
    # If getent is available, use it to retrieve the home directory
    HOME_TEMP=$(getent passwd "$(whoami)" | cut -d: -f6)
    export HOME="${HOME_TEMP}"
    if [[ -n "${HOME}" ]]; then
        info "Using getent to determine HOME: ${HOME}"
    else
        fail "Failed to determine HOME using getent."
        exit 1
    fi
else
    # Fallback: Use eval to get the home directory
    HOME_TEMP=$(eval echo ~)
    export HOME="${HOME_TEMP}"
    if [[ -n "${HOME}" ]]; then
        warn "HOME and getent are unavailable. Using fallback with eval: HOME=${HOME}"
    else
        fail "Failed to determine HOME. Unable to proceed."
        exit 1
    fi
fi

# Determine the script's root directory
# The SCRIPT_DIR variable points to the directory containing the script.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -n "${SCRIPT_DIR}" && -d "${SCRIPT_DIR}" ]]; then
    export SCRIPT_DIR
    info "Script directory determined: ${SCRIPT_DIR}"
else
    fail "Failed to determine the script directory. Exiting."
    exit 1
fi

# Define required files in an array
# These files must exist and be sourced for the script to work correctly.
declare -a REQUIRED_FILES=(
    "${SCRIPT_DIR}/config/config.sh"
    "${SCRIPT_DIR}/lib/display.sh"
    "${SCRIPT_DIR}/lib/lists.sh"
    "${SCRIPT_DIR}/lib/utils.sh"
    "${SCRIPT_DIR}/lib/menu.sh"
    "${SCRIPT_DIR}/lib/safe_source.sh"
)

# Source required files and verify their existence
for file in "${REQUIRED_FILES[@]}"; do
    if [[ -f "${file}" ]]; then
        # Source the file if it exists
        source "${file}" || {
            fail "Failed to source file: ${file}. Exiting."
            exit 1
        }
        pass "Sourced required file: ${file}"
    else
        # Log an error if the file is missing
        fail "Required file is missing: ${file}. Exiting."
        exit 1
    fi
done

# -----------------------------------------------------------------------------
# ---------------------------------- GLOBAL VARIABLES/CHECKS ------------------
# -----------------------------------------------------------------------------

# Check if proxychains is required
_Check_Proxy_Needed

# -----------------------------------------------------------------------------
# ---------------------------------- INIT SETUP -------------------------------
# -----------------------------------------------------------------------------

# Function to create required directories
# This function ensures that all directories listed in the REQUIRED_DIRECTORIES array are created.
function Setup_Directories() {
    # Ensure the directories array is defined
    if [[ -z "${REQUIRED_DIRECTORIES+x}" ]]; then
        fail "Directories array is not defined."
        return "${_FAIL}"
    fi

    # Create directories
    for directory in "${REQUIRED_DIRECTORIES[@]}"; do
        if mkdir -p "${directory}"; then
            success "Created directory ${directory}."
        else
            fail "Failed to create directory ${directory}."
        fi
    done
}

# Function to set up necessary files
# This function ensures the presence of critical files, including configuration files and log files.
function Setup_Necessary_Files() {
    # Ensure the source directory exists
    local src_dir="${SCRIPT_DIR}/config"
    if [[ ! -d "${src_dir}" ]]; then
        fail "Directory [${src_dir}] does not exist."
        return "${_FAIL}"
    fi

    # Ensure PENTEST_DIR exists
    if [[ ! -d "${PENTEST_DIR}" ]]; then
        mkdir -p "${PENTEST_DIR}" || {
            fail "Failed to create directory: ${PENTEST_DIR}"
            return "${_FAIL}"
        }
        success "Created directory: ${PENTEST_DIR}"
    fi

    # Copy configuration files
    for file in "${PENTEST_FILES[@]}"; do
        copy_file "${SCRIPT_DIR}/config/${file}" "${PENTEST_DIR}/${file}"
    done

    # Create or touch log and timestamp files
    for file in "${LOG_FILE}" "${MENU_TIMESTAMP_FILE}"; do
        if [[ ! -e "${file}" ]]; then
            touch "${file}" || {
                fail "Failed to create file: ${file}. Skipping to next file."
                continue  # Skip to the next file in the loop
            }
            success "Created file: ${file}"
        else
            info "File already exists: ${file}"
        fi
    done
}

# Function to configure dotfiles
# This function backs up existing dotfiles and replaces them with new ones from a designated directory.
function Setup_Dot_Files() {
    # Ensure the source directory exists
    local src_dir="${SCRIPT_DIR}/dot"
    if [[ ! -d "${src_dir}" ]]; then
        fail "Directory [${src_dir}] does not exist."
        return "${_FAIL}"
    fi

    for file in "${DOT_FILES[@]}"; do
        local target="${HOME}/.${file}"
        local source="dot/${file}"

        # Copy the new file from the dot directory
        if copy_file "${source}" "${target}"; then
            success "Copied ${source} to ${target}."
        else
            fail "Failed to copy ${source} to ${target}."
        fi
    done

    for file in "${BASH_DOT_FILES[@]}"; do
        local target="${BASH_DIR}/${file}"
        local source="dot/${file}"

        # Copy the new file from the dot directory
        if copy_file "${source}" "${target}"; then
            success "Copied ${source} to ${target}."
        else
            fail "Failed to copy ${source} to ${target}."
        fi
    done

    # Source the new bashrc
    if source "${HOME}/.bashrc"; then
        success "Sourced new ${HOME}/.bashrc."
        return "${_PASS}"
    else
        fail "Failed to source ${HOME}/.bashrc."
        return "${_FAIL}"
    fi
}

# Function to undo the setup of dotfiles
function Undo_Setup_Dot_Files() {
    # Revert dotfiles in the home directory
    for file in "${DOT_FILES[@]}"; do
        local target="${HOME}/.${file}"

        if [[ -f "${target}" ]]; then
            if ! restore_file "${target}"; then
                info "No backup for ${target}. Leaving it untouched."
            else
                success "Restored ${target} from backup."
            fi
        fi
    done

    # Revert dotfiles in the bash directory
    for file in "${BASH_DOT_FILES[@]}"; do
        local target="${BASH_DIR}/${file}"

        if [[ -f "${target}" ]]; then
            if ! restore_file "${target}"; then
                info "No backup for ${target}. Leaving it untouched."
            else
                success "Restored ${target} from backup."
            fi
        fi
    done

    # Reload the bashrc if it was restored
    if source "${HOME}/.bashrc"; then
        success "Reloaded ${HOME}/.bashrc after undoing dotfile setup."
    else
        warn "Failed to reload ${HOME}/.bashrc after undoing dotfile setup."
    fi
}

# Function to set up a cron job for renewing TGTs
# This function copies the renew script, makes it executable, and configures a cron job to run it periodically.
function Setup_Cron_Jobs() {
    # Ensure the source directory exists
    local src_dir="${SCRIPT_DIR}/dot"
    if [[ ! -d "${src_dir}" ]]; then
        fail "Directory [${src_dir}] does not exist."
        return "${_FAIL}"
    fi

    # Copy the renew.tgt.sh script
    if cp dot/renew_tgt.sh "${BASH_DIR}/.renew_tgt.sh"; then
        chmod +x "${BASH_DIR}/renew_tgt.sh"
        success "Copied and set executable permissions for ${HOME}/renew_tgt.sh."
    else
        fail "Failed to copy ${HOME}/renew_tgt.sh."
        return "${_FAIL}"
    fi

    # Create or update the cron job
    if (
        crontab -l 2> /dev/null | grep -v "${BASH_DIR}/renew_tgt.sh"
                                                                     echo "0 */8 * * * ${BASH_DIR}/renew_tgt.sh >> ${BASH_LOG_DIR}/renew_tgt.log 2>&1"
    )                                                                                                                                                   | crontab -; then
        success "Cron job for ${BASH_DIR}/renew_tgt.sh created or updated."
        return "${_PASS}"
    else
        fail "Failed to create or update the Cron job for ${BASH_DIR}/renew_tgt.sh."
        return "${_FAIL}"
    fi
}

# Function to configure Docker's iptables policy
# This function ensures that Docker containers can operate by setting the iptables FORWARD policy to ACCEPT.
function Setup_Docker() {
    # Ensure iptables is available
    if ! command -v iptables &> /dev/null; then
        fail "iptables command not found. Ensure it is installed and accessible."
        return "${_FAIL}"
    fi

    # Allow Docker images to work on the system
    if iptables -P FORWARD ACCEPT; then
        success "Updated iptables policy to ACCEPT for FORWARD."
        return "${_PASS}"
    else
        fail "Failed to update iptables policy."
        return "${_FAIL}"
    fi
}

# Function to copy MSF RC files
# This function checks for the existence of the source directory and the target directory,
# creates the target directory if necessary, and copies all .rc files to it.
function Setup_Msf_Scripts() {
    # Ensure the source directory exists
    local src_dir="${SCRIPT_DIR}/tools/extra/msf"
    if [[ ! -d "${src_dir}" ]]; then
        fail "Directory [${src_dir}] does not exist."
        return "${_FAIL}"
    fi

    # Ensure the target directory exists
    if [[ ! -d "${DATA_DIR}/MSF" ]]; then
        mkdir -p "${DATA_DIR}/MSF" || {
            fail "Failed to create target directory ${DATA_DIR}/MSF."
            return "${_FAIL}"
        }
        success "Created target directory ${DATA_DIR}/MSF."
    fi

    # Copy MSF RC files
    if cp tools/extra/msf/*.rc "${DATA_DIR}/MSF/"; then
        success "Copied MSF RC files to ${DATA_DIR}/MSF/"
        return "${_PASS}"
    else
        fail "Failed to copy MSF RC files to ${DATA_DIR}/MSF/"
        return "${_FAIL}"
    fi
}

# Function to copy support scripts
# This function ensures the source directory exists, then copies all scripts to the base directory.
function Setup_Support_Scripts() {
    # Ensure the source directory exists
    local src_dir="${SCRIPT_DIR}/tools/extra/scripts"
    if [[ ! -d "${src_dir}" ]]; then
        fail "Directory [${src_dir}] does not exist."
        return "${_FAIL}"
    fi

    # Ensure the source directory exists
    # Copy support scripts
    if cp tools/extra/scripts/* "${DATA_DIR}/TOOLS/SCRIPTS/"; then
        success "Copied support scripts to ${DATA_DIR}/TOOLS/SCRIPTS"
        return "${_PASS}"
    else
        fail "Failed to copy support scripts to ${DATA_DIR}/TOOLS/SCRIPTS"
        return "${_FAIL}"
    fi
}

# Function to update DNS configuration to use systemd-resolved
function Fix_Dns() {
    local resolv_conf="/etc/resolv.conf"
    local systemd_resolv_conf="/run/systemd/resolve/resolv.conf"

    # Check if systemd-resolved is active
    if ! systemctl is-active --quiet systemd-resolved; then
        fail "Systemd-resolved is not active. Please start it before updating DNS configuration."
        return "${_FAIL}"
    fi

    # Verify that the systemd-resolved configuration file exists
    if [[ ! -f "${systemd_resolv_conf}" ]]; then
        fail "Systemd-resolved configuration file [${systemd_resolv_conf}] does not exist. Cannot update DNS configuration."
        return "${_FAIL}"
    fi

    # Backup the existing /etc/resolv.conf if it exists and is not a symlink
    if [[ -e "${resolv_conf}" && ! -L "${resolv_conf}" ]]; then
        local backup_file
        backup_file="/etc/resolv.conf.backup.$(date +%s)"
        if ! mv "${resolv_conf}" "${backup_file}"; then
            fail "Failed to backup existing /etc/resolv.conf to [${backup_file}]."
            return "${_FAIL}"
        fi
        info "Backed up existing /etc/resolv.conf to [${backup_file}]."
    fi

    # Remove the existing /etc/resolv.conf symlink or file
    if [[ -e "${resolv_conf}" || -L "${resolv_conf}" ]]; then
        if ! rm -f "${resolv_conf}"; then
            fail "Failed to remove existing /etc/resolv.conf."
            return "${_FAIL}"
        fi
        info "Removed existing /etc/resolv.conf."
    fi

    # Create a symlink to systemd-resolved's configuration
    if ln -s "${systemd_resolv_conf}" "${resolv_conf}"; then
        success "Successfully updated /etc/resolv.conf to use systemd-resolved."
        return "${_PASS}"
    else
        fail "Failed to create symlink from /etc/resolv.conf to [${systemd_resolv_conf}]."
        return "${_FAIL}"
    fi
}

# -----------------------------------------------------------------------------
# ---------------------------------- Install Specific Tools -------------------
# -----------------------------------------------------------------------------

# Function to install Impacket
# This function installs Python dependencies for the Impacket tool.
function Install_Impacket() {
    _Pushd "${TOOLS_DIR}/impacket"

    if _Pip_Install "."; then
        success "Installed pip packages for impacket."
    else
        fail "Failed to install pip packages for impacket."
    fi
    _Popd
}

# Function to move in-house tools
# This function moves and sets up various custom tools into the appropriate directories.
function _Install_Inhouse_Tools() {
    # Ensure the source directory exists
    local src_dir="${SCRIPT_DIR}/tools/extra"
    if [[ ! -d "${src_dir}" ]]; then
        fail "Directory [${src_dir}] does not exist."
        return "${_FAIL}"
    fi

    # Move autoTGT tool
    if [[ -d "${src_dir}/autoTGT" ]]; then
        if mv "${src_dir}/autoTGT" "${TOOLS_DIR}/"; then
            success "Moved autoTGT to ${TOOLS_DIR}/"
        else
            fail "Failed to move autoTGT to ${TOOLS_DIR}/"
        fi
    else
        fail "Source directory [${src_dir}/autoTGT] does not exist. Skipping."
    fi

    # Move and set up Impacket tool
    if [[ -d "${src_dir}/impacket" ]]; then
        if mv "${src_dir}/impacket" "${TOOLS_DIR}/"; then
            success "Moved impacket to ${TOOLS_DIR}/"
            Install_Impacket
        else
            fail "Failed to move impacket to ${TOOLS_DIR}/"
        fi
    else
        fail "Source directory [${src_dir}/impacket] does not exist. Skipping."
    fi

    # Move packedcollection tool
    if [[ -d "${src_dir}/packedcollection" ]]; then
        if mv "${src_dir}/packedcollection" "${TOOLS_DIR}/"; then
            success "Moved packedcollection to ${TOOLS_DIR}/"
        else
            fail "Failed to move packedcollection to ${TOOLS_DIR}/"
        fi
    else
        fail "Source directory [${src_dir}/packedcollection] does not exist. Skipping."
    fi

    # Move precompiled-offensive-bins tool
    if [[ -d "${src_dir}/precompiled-offensive-bins" ]]; then
        if mv "${src_dir}/precompiled-offensive-bins" "${TOOLS_DIR}/"; then
            success "Moved precompiled-offensive-bins to ${TOOLS_DIR}/"
        else
            fail "Failed to move precompiled-offensive-bins to ${TOOLS_DIR}/"
        fi
    else
        fail "Source directory [${src_dir}/precompiled-offensive-bins] does not exist. Skipping."
    fi

    # Move orpheus tool
    if [[ -d "${src_dir}/orpheus" ]]; then
        if mv "${src_dir}/orpheus" "${TOOLS_DIR}/"; then
            success "Moved orpheus to ${TOOLS_DIR}/"
        else
            fail "Failed to move orpheus to ${TOOLS_DIR}/"
        fi
    else
        fail "Source directory [${src_dir}/orpheus] does not exist. Skipping."
    fi
}

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

    success "Reloaded configuration from ${file}."
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
            if ! _Exec_Function "${choice}"; then
                fail "Failed to execute predefined installation function: ${choice}"
                return "${_FAIL}"
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
            info "Found script for custom tool: ${script_file}"

            # Source the script and execute the install function
            source "${script_file}" || {
                fail "Failed to source script: ${script_file}"
                return "${_FAIL}"
            }

            local tool_name="${choice}" # Assuming the tool name matches the choice
            local install_function="install_${tool_name}"

            # Check if the install function exists
            if declare -f "${install_function}" > /dev/null; then
                info "Executing installation function: ${install_function}"
                if ! "${install_function}"; then
                    fail "Installation function failed: ${install_function}"
                    return "${_FAIL}"
                fi
            else
                fail "Installation function not found in script: ${install_function}"
                return "${_FAIL}"
            fi
        else
            fail "Script file not found: ${script_file}"
            return "${_FAIL}"
        fi
    fi

    # Success message if no errors occurred
    success "Tool installation for '${choice}' completed successfully."
    return "${_PASS}"
}

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
    if [[ "${choice}" == "Setup Environment" ]]; then
        _Display_Menu "ENVIRONMENT SETUP" "_Exec_Function" "${ENVIRONMENT_MENU_ITEMS[@]}"
    elif [[ "${choice}" == "Edit Config Files" ]]; then
        _Display_Menu "Configuration Menu" "_Process_Config_Menu" "${CONFIG_MENU_ITEMS[@]}"
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

        _Display_Menu "TOOL INSTALLATION MENU" "_Process_Tool_Install_Menu" "${TOOL_MENU_ITEMS[@]}"
    elif [[ "${choice}" == "Test Tool Installs" ]]; then
        _Test_Tool_Installs
    elif [[ "${choice}" == "Pentest Menu" ]]; then
        _Pentest_Menu
    else
        warn "Invalid option: ${choice}" # Log warning for invalid start menu option
    fi
}

# Ensure fzf is installed and working
_check_fzf

# Display the main setup menu
_Display_Menu "BASH SETUP" "_Process_Start_Menu" "${SETUP_MENU_ITEMS[@]}"
