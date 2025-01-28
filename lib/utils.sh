#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : utils.sh
# DESCRIPTION : Utility script for dynamically sourcing utility scripts and
#               defining commonly used variables and behaviors.
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-15 21:16:38
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-15 21:16:38  | Adam Compton | Initial creation.
# =============================================================================

# Guard to prevent multiple sourcing
if [[ -z "${UTILS_SH_LOADED:-}" ]]; then
    declare -g UTILS_SH_LOADED=true

    # =============================================================================
    # GLOBAL VARIABLES
    # =============================================================================

    export DEBIAN_FRONTEND=noninteractive

    # Validate SCRIPT_DIR
    if [[ -z "${SCRIPT_DIR:-}" ]]; then
        echo "Error: SCRIPT_DIR is not set." >&2
        exit 1
    fi

    # =============================================================================
    # DYNAMIC SCRIPT SOURCING
    # =============================================================================
    # Dynamically source all `utils_*.sh` files from the lib directory

    UTIL_LIB_DIR="${SCRIPT_DIR}/lib"

    if [[ -d "${UTIL_LIB_DIR}" ]]; then
        sourced_any=false
        for utils_file in "${UTIL_LIB_DIR}"/utils_*.sh; do
            if [[ -f "${utils_file}" ]]; then
                source "${utils_file}" || {
                    fail "Failed to source ${utils_file}" >&2
                    exit 1
                }
                pass "Sourced: ${utils_file}" # Logging success
                sourced_any=true
            fi
        done
        if [[ "${sourced_any}" == false ]]; then
            info "No utils_*.sh scripts found to source in ${UTIL_LIB_DIR}"
        fi
    else
        fail "Utility library directory does not exist: ${UTIL_LIB_DIR}" >&2
        exit 1
    fi
fi
