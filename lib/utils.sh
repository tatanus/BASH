#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : utils.sh
# DESCRIPTION :
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

    # pass/fail/true/fall variables
    _PASS=0
    _FAIL=1

    export DEBIAN_FRONTEND=noninteractive

    # Dynamically source all utils_*.sh files from the lib directory
    for utils_file in "${SCRIPT_DIR}"/lib/utils_*.sh; do
        if [[ -f "${utils_file}" ]]; then
            source "${utils_file}"
            info "Sourced: ${utils_file}"
        else
            fail "No matching files to source in ${SCRIPT_DIR}/lib/"
            exit 1
        fi
    done

fi
