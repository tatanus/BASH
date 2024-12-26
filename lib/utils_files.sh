#!/usr/bin/env bash

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

    # Check if an environment variable exists
    # Usage: check_env_var "VAR_NAME"
    function check_env_var() {
        local var_name="$1"
        if [[ -z "${!var_name:-}" ]]; then
            fail "Environment variable $var_name is not set."
        else
            pass "Environment variable $var_name exists."
        fi
    }

    # Generate a unique, sanitized filename based on toolname and optional special tag
    # Usage: generate_filename "toolname" "optional_special"
    function generate_filename() {
        # Ensure toolname is provided
        if [ -z "$1" ]; then
            echo "Error: Toolname argument is required."
            return 1
        fi

        local toolname="$1"
        local special="$2"
        local date_time
        local sanitized_toolname
        local sanitized_special

        # Get the current date and time in the required format
        date_time=$(date +"%Y-%m-%d_%H-%M-%S")

        # Sanitize toolname and special to remove special characters and spaces
        sanitized_toolname=$(echo "$toolname" | tr -c '[:alnum:]' '_')
        sanitized_special=$(echo "$special" | tr -c '[:alnum:]' '_')

        # Build the filename
        if [ -n "$sanitized_special" ]; then
            echo "${sanitized_toolname}_${sanitized_special}_${date_time}.tee"
        else
            echo "${sanitized_toolname}_${date_time}.tee"
        fi
    }

    # Check if a file exists
    # Usage: check_file_exists "file_path"
    function check_file_exists() {
        local file_path="$1"
        if [[ -f "$file_path" ]]; then
            pass "File $file_path exists."
        else
            fail "File $file_path does not exist."
        fi
    }

    # Check if a file is readable
    # Usage: check_file_readable "file_path"
    function check_file_readable() {
        local file_path="$1"
        if [[ -r "$file_path" ]]; then
            pass "File $file_path is readable."
        else
            fail "File $file_path is not readable."
        fi
    }

    # Check if a file is writable
    # Usage: check_file_writable "file_path"
    function check_file_writable() {
        local file_path="$1"
        if [[ -w "$file_path" ]]; then
            pass "File $file_path is writable."
        else
            fail "File $file_path is not writable."
        fi
    }

    # Check if a file is executable
    # Usage: check_file_executable "file_path"
    function check_file_executable() {
        local file_path="$1"
        if [[ -x "$file_path" ]]; then
            pass "File $file_path is executable."
        else
            fail "File $file_path is not executable."
        fi
    }

    # Check if a directory exists
    # Usage: check_dir_exists "dir_path"
    function check_dir_exists() {
        local dir_path="$1"
        if [[ -d "$dir_path" ]]; then
            pass "Directory $dir_path exists."
        else
            fail "Directory $dir_path does not exist."
        fi
    }

    # Check if a directory is readable
    # Usage: check_dir_readable "dir_path"
    function check_dir_readable() {
        local dir_path="$1"
        if [[ -r "$dir_path" ]]; then
            pass "Directory $dir_path is readable."
        else
            fail "Directory $dir_path is not readable."
        fi
    }

    # Check if a directory is writable
    # Usage: check_dir_writable "dir_path"
    function check_dir_writable() {
        local dir_path="$1"
        if [[ -w "$dir_path" ]]; then
            pass "Directory $dir_path is writable."
        else
            fail "Directory $dir_path is not writable."
        fi
    }
fi
