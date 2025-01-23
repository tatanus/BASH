#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : utils_cmd.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2025-01-13 15:56:42
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2025-01-13 15:56:42  | Adam Compton | Initial creation.
# =============================================================================

# Guard to prevent multiple sourcing
if [[ -z "${UTILS_CMD_SH_LOADED:-}" ]]; then
    declare -g UTILS_CMD_SH_LOADED=true

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

    # Helper function: Check command availability
    function check_command() {
        command -v "$1" &> /dev/null
        if [[ $? -ne 0 ]]; then
            echo "$1 is not installed or not functional."
            return 1
        fi
        return 0
    }
fi
