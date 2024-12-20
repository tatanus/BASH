#!/usr/bin/env bash

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

# Initialize the error flag
ERROR_FLAG=false

# Ensure the script is being run under Bash
if [ -z "${BASH_VERSION:-}" ]; then
    echo "[- FAIL  ] Error: This script must be run under Bash."
    ERROR_FLAG=true
fi

# Ensure Bash version is 4.0 or higher
if [[ -n "${BASH_VERSION:-}" && "${BASH_VERSINFO[0]}" -lt 4 ]]; then
    echo "[- FAIL  ] Error: This script requires Bash version 4.0 or higher. Current version: ${BASH_VERSION}"
    ERROR_FLAG=true
fi

# Ensure the script is run as root (user ID 0)
if [[ $EUID -ne 0 ]]; then
    echo "[- FAIL  ] Error: This script must be run as root."
    ERROR_FLAG=true
fi

# If any errors occurred, display a summary and exit
if $ERROR_FLAG; then
    echo
    echo "--------------------------------------------------"
    echo "[- FAIL  ] One or more errors occurred:"
    echo "  - Ensure you are using Bash version 4.0 or higher."
    echo "  - Ensure you are running this script as root."
    echo
    echo "Press any key to exit..."
    read -n 1 -s  # Wait for user to press any key
    echo  # Move to the next line
    #exit 1  # Exit with a failure status code
fi

# Success message if no errors
echo "[+ PASS  ] All checks passed. Continuing script execution."

# -----------------------------------------------------------------------------
# ---------------------------------- IMPORTS/SOURCES --------------------------
# -----------------------------------------------------------------------------

# Check if the HOME environment variable is set
# This determines the home directory of the current user and exports it as MY_HOME.
if [[ -n "$HOME" ]]; then
    # If HOME is set, use it
    export MY_HOME="$HOME"
    echo "[* INFO  ] HOME environment variable is set. Using HOME as MY_HOME: $MY_HOME"
elif command -v getent > /dev/null 2>&1; then
    # If getent is available, use it to retrieve the home directory
    export MY_HOME=$(getent passwd "$(whoami)" | cut -d: -f6)
    if [[ -n "$MY_HOME" ]]; then
        echo "[* INFO  ] Using getent to determine MY_HOME: $MY_HOME"
    else
        echo "[- FAIL  ] Failed to determine MY_HOME using getent."
        exit 1
    fi
else
    # Fallback: Use eval to get the home directory
    export MY_HOME=$(eval echo ~)
    if [[ -n "$MY_HOME" ]]; then
        echo "[! WARN  ] HOME and getent are unavailable. Using fallback with eval: MY_HOME=$MY_HOME"
    else
        fail "[- FAIL  ] Failed to determine MY_HOME. Unable to proceed."
        exit $_FAIL
    fi
fi

# Determine the script's root directory
# The SCRIPT_DIR variable points to the directory containing the script.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -n "$SCRIPT_DIR" && -d "$SCRIPT_DIR" ]]; then
    export SCRIPT_DIR
    echo "[* INFO  ] Script directory determined: $SCRIPT_DIR"
else
    fail "[- FAIL  ] Failed to determine the script directory. Exiting."
    exit 1
fi

# Define required files in an array
# These files must exist and be sourced for the script to work correctly.
declare -a REQUIRED_FILES=(
    "$SCRIPT_DIR/config/config.sh"
    "$SCRIPT_DIR/lib/display.sh"
    "$SCRIPT_DIR/lib/lists.sh"
    "$SCRIPT_DIR/lib/utils.sh"
    "$SCRIPT_DIR/lib/menu.sh"
    "$SCRIPT_DIR/lib/safe_source.sh"
)

# Source required files and verify their existence
for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        # Source the file if it exists
        source "$file" || {
            fail "Failed to source file: $file. Exiting."
            exit $_FAIL
        }
        success "Sourced required file: $file"
    else
        # Log an error if the file is missing
        fail "Required file is missing: $file. Exiting."
        exit $_FAIL
    fi
done

# -----------------------------------------------------------------------------
# ---------------------------------- UBUNTU VER CHECK -------------------------
# -----------------------------------------------------------------------------

# Determine the operating system and version
OS_NAME="$(uname -s)" # Get the OS name using `uname`
export OS_NAME

# Initialize version variables for supported operating systems
export UBUNTU_VER=""
export MACOS_VER=""
export WINDOWS_VER=""

# Case statement to handle different operating systems
case "$OS_NAME" in
    Linux)
        # Check if the _Get_Ubuntu_Version function is available
        if ! command -v _Get_Ubuntu_Version &>/dev/null; then
            fail "Function _Get_Ubuntu_Version is not defined."
            exit $_FAIL
        fi

        UBUNTU_VER=$(_Get_Ubuntu_Version) || {
            fail "Failed to determine Ubuntu version."
            exit $_FAIL
        }

        export UBUNTU_VER
        success "Detected Ubuntu version: $UBUNTU_VER"
        ;;
    Darwin)
        # Check if the _Get_MacOS_Version function is available
        if ! command -v _Get_MacOS_Version &>/dev/null; then
            fail "Function _Get_MacOS_Version is not defined."
            exit $_FAIL
        fi

        MACOS_VER=$(_Get_MacOS_Version) || {
            fail "Failed to determine macOS version."
            exit $_FAIL
        }

        export MACOS_VER
        success "Detected macOS version: $MACOS_VER"
        ;;
    CYGWIN*|MINGW*|MSYS*|Windows_NT)
        # Handle Windows platforms
        # Check if the _Get_Windows_Version function is available
        if ! command -v _Get_Windows_Version &>/dev/null; then
            fail "Function _Get_Windows_Version is not defined."
            exit $_FAIL
        fi

        WINDOWS_VER=$(_Get_Windows_Version) || {
            fail "Failed to determine Windows version."
            exit $_FAIL
        }

        export WINDOWS_VER
        success "Detected Windows version: $WINDOWS_VER"
        ;;
    *)
        # Handle unsupported operating systems
        fail "Unsupported operating system detected: $OS_NAME"
        exit $_FAIL
        ;;
esac

# -----------------------------------------------------------------------------
# ---------------------------------- GLOBAL VARIABLES/CHECKS ------------------
# -----------------------------------------------------------------------------

# Check if proxychains is rewuired
_Check_Proxy_Needed

# -----------------------------------------------------------------------------
# ---------------------------------- INIT SETUP -------------------------------
# -----------------------------------------------------------------------------

# Function to create required directories
# This function ensures that all directories listed in the REQUIRED_DIRECTORIES array are created.
function Setup_Directories() {
    # Ensure the directories array is defined
    if [ -z "${REQUIRED_DIRECTORIES+x}" ]; then
        fail "Directories array is not defined."
        return $_FAIL
    fi

    # Create directories
    for directory in "${REQUIRED_DIRECTORIES[@]}"; do
        if mkdir -p "$directory"; then
            success "Created directory $directory."
        else
            fail "Failed to create directory $directory."
        fi
    done
}

# Function to set up necessary files
# This function ensures the presence of critical files, including configuration files and log files.
function Setup_Necessary_Files() {
    # Ensure the source directory exists
    local src_dir="$SCRIPT_DIR/config"
    if [ ! -d "$src_dir" ]; then
        fail "Directory [$src_dir] does not exist."
        return $_FAIL
    fi

    # Ensure PENTEST_DIR exists
    if [ ! -d "$PENTEST_DIR" ]; then
        mkdir -p "$PENTEST_DIR" || {
            fail "Failed to create directory: $PENTEST_DIR"
            return $_FAIL
        }
        success "Created directory: $PENTEST_DIR"
    fi

    # Internal function to copy files with error handling
    copy_file() {
        local src_file="$1"
        local dest_file="$2"

        if [ -f "$src_file" ]; then
            cp "$src_file" "$dest_file" || {
                fail "Failed to copy $src_file to $dest_file"
                return $_FAIL

            }
            success "Copied $src_file to $dest_file"
        else
            fail "Source file $src_file does not exist. Skipping."
            return $_FAIL
        fi
    }

    # Copy configuration files
    for file in "${PENTEST_FILES[@]}"; do
        copy_file "$SCRIPT_DIR/config/$file" "$PENTEST_DIR/$file"
    done

    # Create or touch log and timestamp files
    for file in "$LOG_FILE" "$MENU_TIMESTAMP_FILE"; do
        if [ ! -e "$file" ]; then
            touch "$file" || {
                fail "Failed to create file: $file. Skipping to next file."
                continue  # Skip to the next file in the loop
            }
            success "Created file: $file"
        else
            info "File already exists: $file"
        fi
    done
}

# Function to configure dotfiles
# This function backs up existing dotfiles and replaces them with new ones from a designated directory.
function Setup_Dot_Files() {
    # Ensure the source directory exists
    local src_dir="$SCRIPT_DIR/dot"
    if [ ! -d "$src_dir" ]; then
        fail "Directory [$src_dir] does not exist."
        return $_FAIL
    fi

    for file in "${DOT_FILES[@]}"; do
        local target="${MY_HOME}/.${file}"
        local source="dot/${file}"

        # Backup existing file if it exists
        if [ -f "$target" ]; then
            if cp "$target" "${target}.old"; then
                success "Backed up existing file $target to ${target}.old."
            else
                fail "Failed to back up existing file $target."
                continue
            fi
        fi

        # Copy the new file from the dot directory
        if cp "$source" "$target"; then
            success "Copied $source to $target."
        else
            fail "Failed to copy $source to $target."
        fi
    done

    # Source the new bashrc
    if source "${MY_HOME}/.bashrc"; then
        success "Sourced new ${MY_HOME}/.bashrc."
        return $_PASS
    else
        fail "Failed to source ${MY_HOME}/.bashrc."
        return $_FAIL
    fi
}

# Function to set up a cron job for renewing TGTs
# This function copies the renew script, makes it executable, and configures a cron job to run it periodically.
function Setup_Cron_Jobs() {
    # Ensure the source directory exists
    local src_dir="$SCRIPT_DIR/dot"
    if [ ! -d "$src_dir" ]; then
        fail "Directory [$src_dir] does not exist."
        return $_FAIL
    fi

    # Copy the renew.tgt.sh script
    if cp dot/renew_tgt.sh "${MY_HOME}/.renew_tgt.sh"; then
        chmod +x "${MY_HOME}/.renew_tgt.sh"
        success "Copied and set executable permissions for ${MY_HOME}/.renew_tgt.sh."
    else
        fail "Failed to copy ${MY_HOME}/.renew_tgt.sh."
        return $_FAIL
    fi

    # Create or update the cron job
    if (crontab -l 2>/dev/null | grep -v "${MY_HOME}/.renew_tgt.sh"; echo "0 */8 * * * ${MY_HOME}/.renew_tgt.sh >> ${MY_HOME}/renew_tgt.log 2>&1") | crontab -; then
        success "Cron job for ${MY_HOME}/.renew_tgt.sh created or updated."
        return $_PASS
    else
        fail "Failed to create or update the Cron job for ${MY_HOME}/.renew_tgt.sh."
        return $_FAIL
    fi
}

# Function to configure Docker's iptables policy
# This function ensures that Docker containers can operate by setting the iptables FORWARD policy to ACCEPT.
function Setup_Docker() {
    # Ensure iptables is available
    if ! command -v iptables &> /dev/null; then
        fail "iptables command not found. Ensure it is installed and accessible."
        return $_FAIL
    fi

    # Allow Docker images to work on the system
    if iptables -P FORWARD ACCEPT; then
        success "Updated iptables policy to ACCEPT for FORWARD."
        return $_PASS
    else
        fail "Failed to update iptables policy."
        return $_FAIL
    fi
}

# Function to copy MSF RC files
# This function checks for the existence of the source directory and the target directory,
# creates the target directory if necessary, and copies all .rc files to it.
function Setup_Msf_Scripts() {
    # Ensure the source directory exists
    local src_dir="$SCRIPT_DIR/tools/extra/msf"
    if [ ! -d "$src_dir" ]; then
        fail "Directory [$src_dir] does not exist."
        return $_FAIL
    fi
    
    # Ensure the target directory exists
    if [[ ! -d "$BASE_DIR/MSF" ]]; then
        mkdir -p "$BASE_DIR/MSF" || {
            fail "Failed to create target directory $BASE_DIR/MSF."
        return $_FAIL
        }
        success "Created target directory $BASE_DIR/MSF."
    fi

    # Copy MSF RC files
    if cp tools/extra/msf/*.rc "$BASE_DIR/MSF/"; then
        success "Copied MSF RC files to $BASE_DIR/MSF/"
        return $_PASS
    else
        fail "Failed to copy MSF RC files to $BASE_DIR/MSF/"
        return $_FAIL
    fi
}

# Function to copy support scripts
# This function ensures the source directory exists, then copies all scripts to the base directory.
function Setup_Support_Scripts() {
    # Ensure the source directory exists
    local src_dir="$SCRIPT_DIR/tools/extra/scripts"
    if [ ! -d "$src_dir" ]; then
        fail "Directory [$src_dir] does not exist."
        return $_FAIL
    fi

    # Ensure the source directory exists
    # Copy support scripts
    if cp tools/extra/scripts/* "$BASE_DIR/"; then
        success "Copied support scripts to $BASE_DIR/"
        return $_PASS
    else
        fail "Failed to copy support scripts to $BASE_DIR/"
        return $_FAIL
    fi
}

# Function to update DNS configuration to use systemd-resolved
function Fix_Dns() {
    local resolv_conf="/etc/resolv.conf"
    local systemd_resolv_conf="/run/systemd/resolve/resolv.conf"

    # Check if systemd-resolved is active
    if ! systemctl is-active --quiet systemd-resolved; then
        fail "Systemd-resolved is not active. Please start it before updating DNS configuration."
        return $_FAIL
    fi

    # Verify that the systemd-resolved configuration file exists
    if [[ ! -f "$systemd_resolv_conf" ]]; then
        fail "Systemd-resolved configuration file [$systemd_resolv_conf] does not exist. Cannot update DNS configuration."
        return $_FAIL
    fi

    # Backup the existing /etc/resolv.conf if it exists and is not a symlink
    if [[ -e "$resolv_conf" && ! -L "$resolv_conf" ]]; then
        local backup_file="/etc/resolv.conf.backup.$(date +%s)"
        if ! mv "$resolv_conf" "$backup_file"; then
            fail "Failed to backup existing /etc/resolv.conf to [$backup_file]."
            return $_FAIL
        fi
        info "Backed up existing /etc/resolv.conf to [$backup_file]."
    fi

    # Remove the existing /etc/resolv.conf symlink or file
    if [[ -e "$resolv_conf" || -L "$resolv_conf" ]]; then
        if ! rm -f "$resolv_conf"; then
            fail "Failed to remove existing /etc/resolv.conf."
            return $_FAIL
        fi
        info "Removed existing /etc/resolv.conf."
    fi

    # Create a symlink to systemd-resolved's configuration
    if ln -s "$systemd_resolv_conf" "$resolv_conf"; then
        success "Successfully updated /etc/resolv.conf to use systemd-resolved."
        return $_PASS
    else
        fail "Failed to create symlink from /etc/resolv.conf to [$systemd_resolv_conf]."
        return $_FAIL
    fi
}

# -----------------------------------------------------------------------------
# ---------------------------------- Install Specific Tools -------------------
# -----------------------------------------------------------------------------

# Function to install Impacket
# This function installs Python dependencies for the Impacket tool.
function Install_Impacket() {
    _Pushd "$TOOL_DIR/impacket"

    if _Pip_Install "." ; then
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
    local src_dir="$SCRIPT_DIR/tools/extra"
    if [ ! -d "$src_dir" ]; then
        fail "Directory [$src_dir] does not exist."
        return $_FAIL
    fi

    # Move autoTGT tool
    if [ -d "$src_dir/autoTGT" ]; then
        if mv "$src_dir/autoTGT" "$TOOL_DIR/"; then
            success "Moved autoTGT to $TOOL_DIR/"
        else
            fail "Failed to move autoTGT to $TOOL_DIR/"
        fi
    else
        fail "Source directory [$src_dir/autoTGT] does not exist. Skipping."
    fi

    # Move and set up Impacket tool
    if [ -d "$src_dir/impacket" ]; then
        if mv "$src_dir/impacket" "$TOOL_DIR/"; then
            success "Moved impacket to $TOOL_DIR/"
            Install_Impacket
        else
            fail "Failed to move impacket to $TOOL_DIR/"
        fi
    else
        fail "Source directory [$src_dir/impacket] does not exist. Skipping."
    fi

    # Move packedcollection tool
    if [ -d "$src_dir/packedcollection" ]; then
        if mv "$src_dir/packedcollection" "$TOOL_DIR/"; then
            success "Moved packedcollection to $TOOL_DIR/"
        else
            fail "Failed to move packedcollection to $TOOL_DIR/"
        fi
    else
        fail "Source directory [$src_dir/packedcollection] does not exist. Skipping."
    fi

    # Move precompiled-offensive-bins tool
    if [ -d "$src_dir/precompiled-offensive-bins" ]; then
        if mv "$src_dir/precompiled-offensive-bins" "$TOOL_DIR/"; then
            success "Moved precompiled-offensive-bins to $TOOL_DIR/"
        else
            fail "Failed to move precompiled-offensive-bins to $TOOL_DIR/"
        fi
    else
        fail "Source directory [$src_dir/precompiled-offensive-bins] does not exist. Skipping."
    fi

    # Move orpheus tool
    if [ -d "$src_dir/orpheus" ]; then
        if mv "$src_dir/orpheus" "$TOOL_DIR/"; then
            success "Moved orpheus to $TOOL_DIR/"
        else
            fail "Failed to move orpheus to $TOOL_DIR/"
        fi
    else
        fail "Source directory [$src_dir/orpheus] does not exist. Skipping."
    fi
}

# -----------------------------------------------------------------------------
# ---------------------------------- Menus ------------------------------------
# -----------------------------------------------------------------------------

# Function to process configuration menu choices
# $1: The user's choice from the configuration menu
function _Process_Config_Menu() {
    local choice="$1"

    case "$choice" in
        "Edit config.sh")
            _Edit_And_Reload_File "$CONFIG_FILE"
            ;;
        "Edit pentest.env")
            _Edit_And_Reload_File "$ENV_FILE"
            ;;
        "Edit pentest.keys")
            _Edit_And_Reload_File "$KEYS_FILE"
            ;;
        "Edit pentest.alias")
            _Edit_And_Reload_File "$ALIAS_FILE"
            ;;
        *)
            warn "Invalid option: $choice" # Log warning for invalid options
            ;;
    esac
}


# Function to open a file in an editor and reload it
# $1: File path to edit and reload
function _Edit_And_Reload_File() {
    local file="$1"

    # Check if the file exists
    if [[ ! -f "$file" ]]; then
        warn "File not found: $file"
        return $_FAIL
    fi

    # Open the file in the user's preferred editor, defaulting to nano
    local editor="${EDITOR:-nano}" # Use $EDITOR if set, otherwise nano
    if ! $editor "$file"; then
        warn "Failed to open $file in editor."
        return $_FAIL
    fi

    # Reload the file after editing
    if ! source "$file"; then
        warn "Failed to source $file after editing."
        return $_FAIL
    fi

    success "Reloaded configuration from $file."
}

# Function to process tool installation menu choices
# $1: The user's choice from the tool installation menu
function _Process_Tool_Install_Menu() {
    local choice="$1"

    # Validate input
    if [[ -z "$choice" ]]; then
        warn "Usage: _Process_Tool_Install_Menu 'option'"
        return $_FAIL
    fi

    # Check if the choice matches a predefined menu item
    if [[ " ${INSTALL_TOOLS_MENU_ITEMS[@]} " =~ " ${choice} " ]]; then
        _Exec_Function "$choice"
    else
        MODULES_DIR="$SCRIPT_DIR/tools/modules"
        local script_file="$MODULES_DIR/${choice}.sh"

        # Check if the script file exists before attempting to execute it
        if [[ -f "$script_file" ]]; then
            info "Executing script: $script_file"
            source "$script_file" || warn "Failed to source $script_file."
            "install_$tool_name"
        else
            fail "Script file not found: $script_file"
        fi
    fi
}

# Function to process start menu choices
# $1: The user's choice from the start menu
function _Process_Start_Menu() {
    local choice="$1"

    # Validate input
    if [[ -z "$choice" ]]; then
        warn "Usage: _Process_Start_Menu 'option'"
        return $_FAIL
    fi

    # Process choices
    if [ "$choice" == "Setup_Environment" ]; then
        _Display_Menu "ENVIRONMENT SETUP" "_Exec_Function" "${ENVIRONMENT_MENU_ITEMS[@]}"
    elif [ "$choice" == "Edit Config Files" ]; then
        _Display_Menu "Configuration Menu" "_Process_Config_Menu" "${CONFIG_MENU_ITEMS[@]}"
    elif [ "$choice" == "Install_Tools" ]; then
        TOOL_MENU_ITEMS=("${INSTALL_TOOLS_MENU_ITEMS[@]}")
        MODULES_DIR="tools/modules"

        # Dynamically add tool names from scripts in MODULES_DIR
        if [[ -d "$MODULES_DIR" ]]; then
            for script in "$MODULES_DIR"/*.sh; do
                if [[ -f "$script" ]]; then
                    tool_name=$(basename "$script" .sh) # Extract the tool name
                    TOOL_MENU_ITEMS+=("$tool_name")
                fi
            done
        else
            warn "Directory not found: $MODULES_DIR"
        fi

        _Display_Menu "TOOL INSTALLATION MENU" "_Process_Tool_Install_Menu" "${TOOL_MENU_ITEMS[@]}"
    elif [ "$choice" == "Test_Tool_Installs" ]; then
        _Test_Tool_Installs
    else
        warn "Invalid option: $choice" # Log warning for invalid start menu option
    fi
}

# Ensure fzf is installed and working
_check_fzf

# Display the main setup menu
_Display_Menu "BASH SETUP" "_Process_Start_Menu" "${SETUP_MENU_ITEMS[@]}"