#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : utils_env.sh
# DESCRIPTION : Utility functions for environment variables
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-15 21:16:38
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-15 21:16:38  | Adam Compton | Initial creation.
# =============================================================================

# Guard to prevent multiple sourcing
if [[ -z "${UTILS_ENV_SH_LOADED:-}" ]]; then
    declare -g UTILS_ENV_SH_LOADED=true

    #   This function checks if an environment variable with the provided name exists and is set.
    #   If the variable is set, it prints the value and returns success.
    #   If the variable is unset or undefined, it prints an error and returns failure.
    function check_env_var() {
        local var_name="$1"

        if [[ -z "${var_name}" ]]; then
            fail "No variable name provided."
            return 0
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

    # Function to remove a given path from $PATH
    function _Remove_From_PATH() {
        local path_to_remove="$1"

        # Check if the path_to_remove is provided
        if [[ -z "${path_to_remove}" ]]; then
            echo "No path provided to remove from \$PATH."
            return "${_FAIL}"
        fi

        # Remove the specified path from $PATH
        PATH_TEMP=$(echo "${PATH}" | sed -e "s|${path_to_remove}:||" \
            -e "s|:${path_to_remove}||" \
            -e "s|${path_to_remove}||")
        export PATH="${PATH_TEMP}"
    }
fi
