#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : utils_curl.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-08 20:11:12
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-08 20:11:12  | Adam Compton | Initial creation.
# =============================================================================

# Guard to prevent multiple sourcing
if [[ -z "${UTILS_CURL_SH_LOADED:-}" ]]; then
    declare -g UTILS_CURL_SH_LOADED=true

    # -----------------------------------------------------------------------------
    # ---------------------------------- CURL FUNCTIONS ---------------------------
    # -----------------------------------------------------------------------------

    # Download a file using curl
    function _Curl() {
        local url="$1"
        local filename="$2"

        # Validate input parameters
        if [[ -z "${url}" ]] || [[ -z "${filename}" ]]; then
            fail "Usage: _Curl <url> <filename>"
            return "${_FAIL}"
        fi

        # Attempt to download the file
        if ${PROXY} curl -sSL "${url}" -o "${filename}" > /dev/null 2>&1; then
            success "Downloaded ${url} to ${filename}."
            return "${_PASS}"
        else
            fail "Failed to download ${url} to ${filename}."
            return "${_FAIL}"
        fi
    }
fi
