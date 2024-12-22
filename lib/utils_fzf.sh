#!/usr/bin/env bash

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
        read -p "Do you want to install fzf? (Y/n): " answer

        # Set default answer to "Y" if no input is provided
        answer=${answer:-Y}
        case $answer in
            [Yy]* )
                _install_fzf
                ;;
            [Nn]* )
                warning "fzf will not be installed. Exiting."
                exit $_FAIL
                ;;
            * )
                fail "Invalid response. Exiting."
                exit $_FAIL
                ;;
        esac
    }

    # Function to install fzf based on the detected operating system
    function _install_fzf() {
        info "Installing fzf for $OS_NAME..."
        case "$OS_NAME" in
            Linux)
                if [ -n "$UBUNTU_VER" ]; then
                    sudo apt update
                    sudo apt install -y fzf
                    if [ $? -eq 0 ]; then
                        success "fzf has been installed successfully on Ubuntu."
                    else
                        fail "Failed to install fzf on Ubuntu."
                        exit $_FAIL
                    fi
                else
                    fail "Unsupported Linux distribution. Please install fzf manually."
                    exit $_FAIL
                fi
                ;;
            Darwin)
                if command -v brew &>/dev/null; then
                    brew install fzf
                    if [ $? -eq 0 ]; then
                        success "fzf has been installed successfully on macOS."
                    else
                        fail "Failed to install fzf on macOS."
                        exit $_FAIL
                    fi
                else
                    fail "Homebrew is not installed. Please install Homebrew first and try again."
                    exit $_FAIL
                fi
                ;;
            CYGWIN*|MINGW*|MSYS*|Windows_NT)
                fail "Automatic installation for Windows is not supported. Please install fzf manually using Chocolatey, Scoop, or download it from https://github.com/junegunn/fzf."
                ;;
            *)
                fail "Unsupported operating system: $OS_NAME. Please install fzf manually."
                exit $_FAIL
                ;;
        esac
    }
fi