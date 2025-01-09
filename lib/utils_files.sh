#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : utils_files.sh
# DESCRIPTION : Utility functions for validating files, directories, and environment variables
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-15 21:16:38
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-15 21:16:38  | Adam Compton | Initial creation.
# =============================================================================

# Guard to prevent multiple sourcing
if [[ -z "${UTILS_FILES_SH_LOADED:-}" ]]; then
    declare -g UTILS_FILES_SH_LOADED=true

    #   This function checks if an environment variable with the provided name exists and is set.
    #   If the variable is set, it prints the value and returns success.
    #   If the variable is unset or undefined, it prints an error and returns failure.
    function check_env_var() {
        local var_name="$1"

        if [[ -z "${var_name}" ]]; then
            fail "No variable name provided."
            return 1
        fi

        # Use indirect expansion to check if the variable is set and retrieve its value
        if [[ -n "${!var_name+x}" ]]; then
            pass "Environment variable ${var_name} exists and is set."
            return 0
        else
            fail "Environment variable ${var_name} is not set."
            return 1
        fi
    }

    # =============================================================================
    # FUNCTION: _check_tool
    # DESCRIPTION: Verifies that a required tool is installed and executable.
    # =============================================================================
    # Usage:
    # _check_tool TOOL
    # - TOOL: Name of the command-line tool to check.
    # - Outputs an error message if the tool is not found or not executable.
    # - Returns:
    #   - 0: Tool is installed and executable.
    #   - 1: Tool is missing or not executable.
    # =============================================================================
    function check_tool() {
        local tool="$1"

        if ! command -v "${tool}" > /dev/null 2>&1; then
            fail "Tool '${tool}' is not installed or not found in PATH."
            return 1
        else
            return 0
        fi
    }

    # Generate a unique, sanitized filename based on toolname and optional special tag
    # Usage: generate_filename "toolname" "optional_special"
    function generate_filename() {
        if [[ -z "$1" ]]; then
            fail "Error: Toolname argument is required."
            return 1
        fi

        local toolname="$1"
        local special="$2"
        local date_time
        local sanitized_toolname
        local sanitized_special

        date_time=$(date --utc +"%Y-%m-%d_%H-%M-%S") || {
            fail "Failed to get date."
            return 1
        }

        sanitized_toolname=$(echo "${toolname}" | tr -c '[:alnum:]' '_')
        sanitized_special=$(echo "${special}" | tr -c '[:alnum:]' '_')

        if [[ -n "${sanitized_special}" ]]; then
            echo "${sanitized_toolname}_${sanitized_special}_${date_time}.tee"
        else
            echo "${sanitized_toolname}_${date_time}.tee"
        fi
    }

    # Check if a file exists
    # Usage: check_file_exists "file_path"
    function check_file_exists() {
        local file_path="$1"

        if [[ -z "${file_path}" ]]; then
            fail "No file path provided."
            return 1
        fi

        if [[ -f "${file_path}" ]]; then
            pass "File ${file_path} exists."
            return 0
        else
            fail "File ${file_path} does not exist."
            return 1
        fi
    }

    # Check if a file is readable
    # Usage: check_file_readable "file_path"
    function check_file_readable() {
        local file_path="$1"

        if [[ -r "${file_path}" ]]; then
            fail "No file path provided."
            return 1
        fi

        if [[ -f "${file_path}" ]]; then
            pass "File ${file_path} is readable."
            return 0
        else
            fail "File ${file_path} is not readable."
            return 1
        fi
    }

    # Check if a file is writable
    # Usage: check_file_writable "file_path"
    function check_file_writable() {
        local file_path="$1"

        if [[ -w "${file_path}" ]]; then
            fail "No file path provided."
            return 1
        fi

        if [[ -f "${file_path}" ]]; then
            pass "File ${file_path} is writable."
            return 0
        else
            fail "File ${file_path} is not writable."
            return 1
        fi
    }

    # Check if a file is executable
    # Usage: check_file_executable "file_path"
    function check_file_executable() {
        local file_path="$1"

        if [[ -x "${file_path}" ]]; then
            fail "No file path provided."
            return 1
        fi

        if [[ -f "${file_path}" ]]; then
            pass "File ${file_path} is executable."
            return 0
        else
            fail "File ${file_path} is not executable."
            return 1
        fi
    }

    # Copy a file from src to dest with backup handling
    # Usage: copy_with_backup "src" "dest"
    function copy_file() {
        local src="$1"
        local dest="$2"

        # Check if source file exists
        if [[ ! -f "${src}" ]]; then
            fail "Source file does not exist: ${src}"
            return "${_FAIL}"
        fi

        # Check if destination directory exists
        local dest_dir
        dest_dir=$(dirname "${dest}")
        if [[ ! -d "${dest_dir}" ]]; then
            fail "Destination directory does not exist: ${dest_dir}"
            return "${_FAIL}"
        fi

        # Handle existing destination file with .old-<num> backups
        if [[ -f "${dest}" ]]; then
            local backup_num=0
            local backup_file

            while :; do
                backup_file="${dest}.old-${backup_num}"
                if [[ ! -f "${backup_file}" ]]; then
                    if mv "${dest}" "${backup_file}"; then
                        pass "Moved existing file to ${backup_file}"
                    else
                        # Handle the failure
                        fail "Failed to move ${dest} to ${backup_file}"
                        return "${_FAIL}"
                    fi
                    break
                fi
                ((backup_num++))
            done
        fi

        # Copy the source file to the destination
        if cp "${src}" "${dest}"; then
            pass "Copied ${src} to ${dest}"
        else
            # Handle the failure
            fail "Failed to copy ${src} to ${dest}"
            return "${_FAIL}"
        fi
    }

    # Restore the highest numbered <filename>.old-<num> to <filename>
    # Usage: restore_file "filename"
    function restore_file() {
        local filename="$1"

        # Ensure the filename argument is provided
        if [[ -z "${filename}" ]]; then
            fail "No filename provided."
            return "${_FAIL}"
        fi

        # Find all backup files matching <filename>.old-<num>
        local backups
        mapfile -t backups < <(ls "${filename}.old-"* 2> /dev/null || true)

        # Check if there are any backups
        if [[ ${#backups[@]} -eq 0 ]]; then
            info "No backups found for ${filename}. Nothing to restore."
            return "${_PASS}"
        fi

        # Find the highest numbered backup
        local highest_backup
        highest_backup=$(printf "%s\n" "${backups[@]}" | sort -V | tail -n 1)

        # Restore the highest numbered backup
        if mv "${highest_backup}" "${filename}"; then
            pass "Restored ${highest_backup} to ${filename}"
            return "${_PASS}"
        else
            fail "Failed to restore ${highest_backup} to ${filename}"
            return "${_FAIL}"
        fi
    }

    # Check if a directory exists
    # Usage: check_dir_exists "dir_path"
    function check_dir_exists() {
        local dir_path="$1"

        if [[ -z "${dir_path}" ]]; then
            fail "No directory path provided."
            return 1
        fi

        if [[ -d "${dir_path}" ]]; then
            pass "Directory ${dir_path} exists."
            return 0
        else
            fail "Directory ${dir_path} does not exist."
            return 1
        fi
    }

    # Check if a directory is readable
    # Usage: check_dir_readable "dir_path"
    function check_dir_readable() {
        local dir_path="$1"

        if [[ -r "${dir_path}" ]]; then
            fail "No directory path provided."
            return 1
        fi

        if [[ -d "${dir_path}" ]]; then
            pass "Directory ${dir_path} is readable."
            return 0
        else
            fail "Directory ${dir_path} is not readable."
            return 1
        fi
    }

    # Check if a directory is writable
    # Usage: check_dir_writable "dir_path"
    function check_dir_writable() {
        local dir_path="$1"

        if [[ -w "${dir_path}" ]]; then
            fail "No directory path provided."
            return 1
        fi

        if [[ -d "${dir_path}" ]]; then
            pass "Directory ${dir_path} is writable."
            return 0
        else
            fail "Directory ${dir_path} is not writable."
            return 1
        fi
    }
fi
