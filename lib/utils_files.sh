#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : utils_files.sh
# DESCRIPTION : Utility functions for validating files
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

    # Generate a unique, sanitized filename based on toolname and optional special tag
    # Usage: generate_filename "toolname" "optional_special"
    function generate_filename() {
        if [[ -z "$1" ]]; then
            fail "Error: Toolname argument is required."
            return "${_FAIL}"
        fi

        local toolname="$1"
        local special="$2"
        local date_time
        local sanitized_toolname
        local sanitized_special

        date_time=$(date --utc +"%Y-%m-%d_%H-%M-%S") || {
            fail "Failed to get date."
            return "${_FAIL}"
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
            return "${_PASS}"
        fi

        if [[ -f "${file_path}" ]]; then
            pass "File ${file_path} exists."
            return "${_PASS}"
        else
            fail "File ${file_path} does not exist."
            return "${_FAIL}"
        fi
    }

    # Check if a file is readable
    # Usage: check_file_readable "file_path"
    function check_file_readable() {
        local file_path="$1"

        if [[ -z "${file_path}" ]]; then
            fail "No file path provided."
            return "${_PASS}"
        fi

        if [[ -f "${file_path}" && -r "${file_path}" ]]; then
            pass "File ${file_path} is readable."
            return "${_PASS}"
        else
            fail "File ${file_path} is not readable."
            return "${_FAIL}"
        fi
    }

    # Check if a file exists and is non-empty
    # Usage: is_file_non_empty "file_path"
    function is_file_non_empty() {
        local file_path="$1"

        if [[ -z "${file_path}" ]]; then
            fail "No file path provided."
            return "${_FAIL}"
        fi

        if [[ -s "${file_path}" ]]; then
            pass "File ${file_path} exists and is not empty."
            return "${_PASS}"
        else
            fail "File ${file_path} does not exist or is empty."
            return "${_FAIL}"
        fi
    }

    # Check if a file is writable
    # Usage: check_file_writable "file_path"
    function check_file_writable() {
        local file_path="$1"

        if [[ -z "${file_path}" ]]; then
            fail "No file path provided."
            return "${_PASS}"
        fi

        if [[ -f "${file_path}" && -w "${file_path}" ]]; then
            pass "File ${file_path} is writable."
            return "${_PASS}"
        else
            fail "File ${file_path} is not writable."
            return "${_FAIL}"
        fi
    }

    # Check if a file is executable
    # Usage: check_file_executable "file_path"
    function check_file_executable() {
        local file_path="$1"

        if [[ -z "${file_path}" ]]; then
            fail "No file path provided."
            return "${_PASS}"
        fi

        if [[ -f "${file_path}" && -x "${file_path}" ]]; then
            pass "File ${file_path} is executable."
            return "${_PASS}"
        else
            fail "File ${file_path} is not executable."
            return "${_FAIL}"
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

    # Replaces placeholders in a file with their corresponding environment values.
    # Placeholders should be formatted as --VAR_NAME-- and will be replaced with
    # the value of the corresponding ${VAR_NAME} environment variable.
    function replace_env_variables_in_file() {
        local file_path="$1"

        # Ensure file is provided
        if [[ -z "${file_path}" ]]; then
            fail "Error: No file path provided."
            return "${_FAIL}"
        fi

        # Ensure file is readable
        check_file_readable "${file_path}"
        if [[ $? -eq "${_FAIL}" ]]; then
            return "${_FAIL}"
        fi

        # Ensure file is writable
        check_file_writable "${file_path}"
        if [[ $? -eq "${_FAIL}" ]]; then
            return "${_FAIL}"
        fi

        # Extract all placeholders (formatted as --VAR_NAME--)
        local placeholders
        placeholders=$(grep -oP -- "--[A-Z0-9_]+--" "${file_path}" | sort -u || true)

        # If no placeholders are found, return
        if [[ -z "${placeholders}" ]]; then
            pass "No placeholders found in '${file_path}'."
            return "${_PASS}"
        fi

        # Create a temporary file to prevent corruption in case of failure
        temp_file=$(mktemp)
        if [[ $? -ne 0 ]]; then
            fail "Error: Failed to create temp file."
            return "${_FAIL}"
        fi

        cp "${file_path}" "${temp_file}"  # Backup the original file before modification

        for placeholder in ${placeholders}; do
            # Convert --VAR_NAME-- to VAR_NAME (remove --)
            local var_name="${placeholder//--/}"

            # Check if the environment variable exists using check_env_var
            check_env_var "${var_name}"
            if [[ $? -eq "${_FAIL}" ]]; then
                fail "Skipping replacement for '${placeholder}' because '${var_name}' is not set."
                continue
            fi

            # Perform the replacement
            sed -i "s|${placeholder}|${!var_name}|g" "${temp_file}"
            pass "Replaced '${placeholder}' with '${!var_name}'."
        done

        # Move the temp file back to original
        mv "${temp_file}" "${file_path}"

        pass "File successfully updated: ${file_path}"
        return "${_PASS}"
    }
fi
