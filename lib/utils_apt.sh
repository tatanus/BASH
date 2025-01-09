#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : utils_apt.sh
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
if [[ -z "${UTILS_APT_SH_LOADED:-}" ]]; then
    declare -g UTILS_APT_SH_LOADED=true

    # -----------------------------------------------------------------------------
    # ---------------------------------- APT-GET FUNCTIONS ------------------------
    # -----------------------------------------------------------------------------

    # Install a package using apt if it's not already installed
    function _Apt_Install() {
        local package="$1"

        # Verify that package is not empty
        if [[ -z "${package}" ]]; then
            fail "Package name cannot be empty."
            return "${_FAIL}"
        fi

        # Check if the package is already installed
        if ! dpkg -s "${package}" > /dev/null 2>&1; then
            info "Installing ${package} using apt..."
            if ${PROXY} sudo apt update -qq > /dev/null 2>&1 &&
                ${PROXY} sudo apt install -y "${package}" > /dev/null 2>&1; then
                pass "Installed ${package} using apt."
                return "${_PASS}"
            else
                fail "Could not install ${package} using apt."
                return "${_FAIL}"
            fi
        else
            pass "${package} is already installed."
            return "${_PASS}"
        fi

        # shellcheck disable=SC2317
        fail "Something went wrong while installing ${package}."
        # shellcheck disable=SC2317
        return "${_FAIL}"
    }

    # Install all missing apt packages from the apt_packages array
    function _Install_Missing_Apt_Packages() {
        # Ensure the apt_packages array is defined
        if [[ -z "${APT_PACKAGES+x}" ]]; then
            fail "apt_packages array is not defined."
            return "${_FAIL}"
        fi

        local apt_packages_valid=()

        # Validate each package and add to the valid list if it exists
        for package in "${APT_PACKAGES[@]}"; do
            if ${PROXY} apt show "${package}" 2> /dev/null | grep -qvz 'State:.*(virtual)'; then
                apt_packages_valid+=("${package}")
            fi
        done

        # Install all valid packages
        if ! ${PROXY} apt -qq -y install "${apt_packages_valid[@]}" > /dev/null 2>&1; then
            fail "Failed to install one or more packages."
            return "${_FAIL}"
        fi
        _Wait_Pid

        # Verify that each package is properly installed
        for package in "${apt_packages_valid[@]}"; do
            if ! dpkg -s "${package}" > /dev/null 2>&1; then
                fail "${package} is not installed."
                return "${_FAIL}"
            else
                pass "${package} is installed."
            fi
        done

        return "${_PASS}"
    }

    # Perform a full apt update, autoremove, clean, and upgrade
    function _Apt_Update() {
        # Update package list
        if ! ${PROXY} apt -qq -y update --fix-missing > /dev/null 2>&1; then
            fail "Failed to update package list."
            return "${_FAIL}"
        fi
        _Wait_Pid
        pass "Package list updated successfully."

        # Remove unnecessary packages
        if ! ${PROXY} apt -qq -y autoremove > /dev/null 2>&1; then
            fail "Failed to remove unnecessary packages."
            return "${_FAIL}"
        fi
        _Wait_Pid
        pass "Unnecessary packages removed successfully."

        # Clean up the package cache
        if ! ${PROXY} apt -qq -y clean > /dev/null 2>&1; then
            fail "Failed to clean package cache."
            return "${_FAIL}"
        fi
        _Wait_Pid
        pass "Package cache cleaned successfully."

        # Upgrade installed packages
        if ! ${PROXY} apt -qq -y upgrade > /dev/null 2>&1; then
            fail "Failed to upgrade packages."
            return "${_FAIL}"
        fi
        _Wait_Pid
        pass "Packages upgraded successfully."

        return "${_PASS}"
    }
fi
