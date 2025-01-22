#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : safe_source.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-19 15:24:14
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-19 15:24:14  | Adam Compton | Initial creation.
# =============================================================================

# Guard to prevent multiple sourcing
if [[ -z "${SAFE_SOURCE_SH_LOADED:-}" ]]; then
    declare -g SAFE_SOURCE_SH_LOADED=true

    # Stack to track environment snapshots for nested sourcing
    declare -a _SAFE_SOURCE_STACK

    # Take a snapshot of the current environment
    function _TAKE_ENV_SNAPSHOT() {
        local snapshot_id="$1"

        # Capture variables, functions, aliases, and exported variables
        compgen -v >"/tmp/env_vars_${snapshot_id}"
        compgen -A function >"/tmp/env_funcs_${snapshot_id}"
        alias >"/tmp/env_aliases_${snapshot_id}"
        env >"/tmp/env_exported_${snapshot_id}"
    }

    # Save the current environment snapshot and push to the stack
    function _SAVE_ENVIRONMENT() {
        local script="$1"
        local snapshot_id
        snapshot_id="$(basename "${script}")_$$"  # Unique identifier using script name and PID

        # Push the snapshot ID to the stack
        _SAFE_SOURCE_STACK+=("${snapshot_id}")

        # Take a snapshot of the current environment
        _TAKE_ENV_SNAPSHOT "${snapshot_id}"
    }

    # Safely source a script and track changes
    function _SAFE_SOURCE_SCRIPT() {
        local script="$1"

        # Ensure the script exists
        if [[ ! -f "${script}" ]]; then
            echo "Error: Script '${script}' does not exist." >&2
            return 1
        fi

        # Save the current environment state
        _SAVE_ENVIRONMENT "${script}"

        # Source the specified script
        source "${script}"
    }

    # Safely "unsource" a script by reverting the changes made by sourcing
    function _SAFE_UNSOURCE() {
        # Ensure there is a snapshot to revert
        if [[ ${#_SAFE_SOURCE_STACK[@]} -eq 0 ]]; then
            echo "Error: No environment snapshot to unsource." >&2
            return 1
        fi

        # Get the most recent snapshot ID from the stack
        local snapshot_id="${_SAFE_SOURCE_STACK[-1]}"
        unset '_SAFE_SOURCE_STACK[-1]'  # Pop the stack

        # Take a new snapshot of the current environment
        local vars_after funcs_after aliases_after exported_after
        compgen -v >/tmp/env_vars_after_$$
        compgen -A function >/tmp/env_funcs_after_$$
        alias >/tmp/env_aliases_after_$$
        env >/tmp/env_exported_after_$$

        # Revert variables added or modified
        for var in $(comm -13 "/tmp/env_vars_${snapshot_id}" /tmp/env_vars_after_$$); do
            unset "${var}"
        done

        # Revert functions added or modified
        for func in $(comm -13 "/tmp/env_funcs_${snapshot_id}" /tmp/env_funcs_after_$$); do
            unset -f "${func}"
        done

        # Revert aliases added or modified
        for alias in $(comm -13 "/tmp/env_aliases_${snapshot_id}" /tmp/env_aliases_after_$$); do
            unalias "${alias%%=*}" 2>/dev/null
        done

        # Revert exported variables added or modified
        for exported in $(comm -13 "/tmp/env_exported_${snapshot_id}" /tmp/env_exported_after_$$); do
            export_name="${exported%%=*}"  # Extract variable name
            original_value=$(grep "^${export_name}=" "/tmp/env_exported_${snapshot_id}" | cut -d= -f2-)
            export "${export_name}=${original_value}"
        done

        # Cleanup snapshot files
        rm -f "/tmp/env_vars_${snapshot_id}" "/tmp/env_funcs_${snapshot_id}" \
            "/tmp/env_aliases_${snapshot_id}" "/tmp/env_exported_${snapshot_id}" \
            /tmp/env_vars_after_$$ /tmp/env_funcs_after_$$ \
            /tmp/env_aliases_after_$$ /tmp/env_exported_after_$$

        echo "Reverted environment to the state before sourcing '${snapshot_id}'."
    }
fi
