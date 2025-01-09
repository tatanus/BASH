#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : utils_brew.sh
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
if [[ -z "${UTILS_BREW_SH_LOADED:-}" ]]; then
    declare -g UTILS_BREW_SH_LOADED=true

    # -----------------------------------------------------------------------------
    # ---------------------------------- BREW-GET FUNCTIONS -----------------------
    # -----------------------------------------------------------------------------

    # Install a package using Homebrew if it's not already installed
    function _brew_install() {
        local package="$1"

        # Verify that package name is provided
        if [[ -z "${package}" ]]; then
            fail "Package name cannot be empty."
            return "${_FAIL}"
        fi

        # Check if Homebrew is installed
        if ! command -v brew > /dev/null 2>&1; then
            fail "Homebrew is not installed. Please install Homebrew and try again."
            return "${_FAIL}"
        fi

        # Check if the package is already installed
        if brew list --formula | grep -q "^${package}\$"; then
            pass "${package} is already installed via Homebrew."
            return "${_PASS}"
        fi

        # Attempt to install the package
        info "Installing ${package} using Homebrew..."
        if ${PROXY} brew install "${package}"; then
            pass "Successfully installed ${package} using Homebrew."
            return "${_PASS}"
        else
            fail "Failed to install ${package} using Homebrew."
            return "${_FAIL}"
        fi
    }

fi
