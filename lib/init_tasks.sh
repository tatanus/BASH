#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : init_tasks.sh
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
if [[ -z "${INIT_TASKS_SH_LOADED:-}" ]]; then
    declare -g INIT_TASKS_LOADED=true

    # -----------------------------------------------------------------------------
    # ---------------------------------- INIT SETUP -------------------------------
    # -----------------------------------------------------------------------------

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
                pass "Copied ${source} to ${target}."
            else
                fail "Failed to copy ${source} to ${target}."
            fi
        done

        for file in "${BASH_DOT_FILES[@]}"; do
            local target="${BASH_DIR}/${file}"
            local source="dot/${file}"

            # Copy the new file from the dot directory
            if copy_file "${source}" "${target}"; then
                pass "Copied ${source} to ${target}."
            else
                fail "Failed to copy ${source} to ${target}."
            fi
        done

        # Source the new bashrc
        if source "${HOME}/.bashrc"; then
            pass "Sourced new ${HOME}/.bashrc."
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
                    pass "Restored ${target} from backup."
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
                    pass "Restored ${target} from backup."
                fi
            fi
        done

        # Reload the bashrc if it was restored
        if source "${HOME}/.bashrc"; then
            pass "Reloaded ${HOME}/.bashrc after undoing dotfile setup."
        else
            warn "Failed to reload ${HOME}/.bashrc after undoing dotfile setup."
        fi
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

        # Ensure BASH_DIR exists
        if [[ ! -d "${BASH_DIR}" ]]; then
            mkdir -p "${BASH_DIR}" || {
                fail "Failed to create directory: ${BASH_DIR}"
                return "${_FAIL}"
            }
            pass "Created directory: ${BASH_DIR}"
        fi

        # Copy configuration files
        for file in "${PENTEST_FILES[@]}"; do
            copy_file "${SCRIPT_DIR}/dot/${file}" "${BASH_DIR}/${file}"
        done

        # Create or touch log and timestamp files
        for file in "${LOG_FILE}" "${MENU_TIMESTAMP_FILE}"; do
            if [[ ! -e "${file}" ]]; then
                touch "${file}" || {
                    fail "Failed to create file: ${file}. Skipping to next file."
                    continue  # Skip to the next file in the loop
                }
                pass "Created file: ${file}"
            else
                info "File already exists: ${file}"
            fi
        done
    }

    # Function to create required directories
    # This function ensures that all directories listed in the REQUIRED_DIRECTORIES array are created.
    function Setup_Directories() {
        Setup_Pentest_Directories
        Setup_Engagement_Directories
    }

    # Function to create required directories
    # This function ensures that all directories listed in the REQUIRED_DIRECTORIES array are created.
    function Setup_Pentest_Directories() {
        # Ensure the directories array is defined
        if [[ -z "${PENTEST_REQUIRED_DIRECTORIES+x}" ]]; then
            fail "Directories array is not defined."
            return "${_FAIL}"
        fi

        # Create directories
        for directory in "${PENTEST_REQUIRED_DIRECTORIES[@]}"; do
            if mkdir -p "${directory}"; then
                pass "Created directory ${directory}."
            else
                fail "Failed to create directory ${directory}."
            fi
        done
    }

    # Function to create required directories
    # This function ensures that all directories listed in the REQUIRED_DIRECTORIES array are created.
    function Setup_Engagement_Directories() {
        # Ensure the directories array is defined
        if [[ -z "${ENGAGEMENT_REQUIRED_DIRECTORIES+x}" ]]; then
            fail "Directories array is not defined."
            return "${_FAIL}"
        fi

        # Create directories
        for directory in "${ENGAGEMENT_REQUIRED_DIRECTORIES[@]}"; do
            if mkdir -p "${directory}"; then
                pass "Created directory ${directory}."
            else
                fail "Failed to create directory ${directory}."
            fi
        done
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
        if cp dot/renew_tgt.sh "${BASH_DIR}/renew_tgt.sh"; then
            chmod +x "${BASH_DIR}/renew_tgt.sh"
            pass "Copied and set executable permissions for ${HOME}/renew_tgt.sh."
        else
            fail "Failed to copy ${HOME}/renew_tgt.sh."
            return "${_FAIL}"
        fi

        # Create or update the cron job
        if {
            crontab -l 2> /dev/null | grep -v "${BASH_DIR}/renew_tgt.sh"
            echo "0 */8 * * * ${BASH_DIR}/renew_tgt.sh >> ${BASH_LOG_DIR}/renew_tgt.log 2>&1"
        } | crontab -; then
            pass "Cron job for ${BASH_DIR}/renew_tgt.sh created or updated."
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
            pass "Updated iptables policy to ACCEPT for FORWARD."
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
        if [[ ! -d "${TOOLS_DIR}/SCRIPTS/MSF" ]]; then
            mkdir -p "${TOOLS_DIR}/SCRIPTS/MSF" || {
                fail "Failed to create target directory ${TOOLS_DIR}/SCRIPTS/MSF."
                return "${_FAIL}"
            }
            pass "Created target directory ${TOOLS_DIR}/SCRIPTS/MSF."
        fi

        # Copy MSF RC files
        if cp tools/extra/msf/*.rc "${TOOLS_DIR}/SCRIPTS/MSF/"; then
            pass "Copied MSF RC files to ${TOOLS_DIR}/SCRIPTS/MSF/"
            return "${_PASS}"
        else
            fail "Failed to copy MSF RC files to ${TOOLS_DIR}/SCRIPTS/MSF/"
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
        if cp tools/extra/scripts/* "${TOOLS_DIR}/SCRIPTS/"; then
            pass "Copied support scripts to ${TOOLS_DIR}/SCRIPTS"
            return "${_PASS}"
        else
            fail "Failed to copy support scripts to ${TOOLS_DIR}/SCRIPTS"
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
            pass "Successfully updated /etc/resolv.conf to use systemd-resolved."
            return "${_PASS}"
        else
            fail "Failed to create symlink from /etc/resolv.conf to [${systemd_resolv_conf}]."
            return "${_FAIL}"
        fi
    }
fi
