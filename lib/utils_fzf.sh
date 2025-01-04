#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : utils_fzf.sh
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
if [[ -z "${UTILS_FZF_SH_LOADED:-}" ]]; then
    declare -g UTILS_FZF_SH_LOADED=true

    # -----------------------------------------------------------------------------
    # ---------------------------------- FZF FUNCTIONS ----------------------------
    # -----------------------------------------------------------------------------

    # Function to check if fzf is installed
    function _check_fzf() {
        if command -v fzf &> /dev/null; then
            info "fzf is already installed."
        else
            fail "fzf is not installed."
            _prompt_install_fzf
        fi
    }

    # Function to prompt the user to install fzf
    function _prompt_install_fzf() {
        read -r -p "Do you want to install fzf? (Y/n): " answer

        # Set default answer to "Y" if no input is provided
        answer=${answer:-Y}
        case ${answer} in
            [Yy]*)
                _install_package "fzf"
                ;;
            [Nn]*)
                warning "fzf will not be installed. Exiting."
                exit "${_FAIL}"
                ;;
            *)
                fail "Invalid response. Exiting."
                exit "${_FAIL}"
                ;;
        esac
    }

fi
