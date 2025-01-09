#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : utils_py.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 20:51:59
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 20:51:59  | Adam Compton | Initial creation.
# =============================================================================

# Guard to prevent multiple sourcing
if [[ -z "${UTILS_PY_SH_LOADED:-}" ]]; then
    declare -g UTILS_PY_SH_LOADED=true

    # -----------------------------------------------------------------------------
    # ---------------------------------- PYTHON CHECKS--- -------------------------
    # -----------------------------------------------------------------------------

    if ! { [[ "${COMPILE_PYTHON}" = false ]] && [[ "${INSTALL_PYTHON}" = false ]]; } && [[ "${COMPILE_PYTHON}" = "${INSTALL_PYTHON}" ]]; then

        fail "Both COMPILE_PYTHON and INSTALL_PYTHON can not be 'true'"
        exit 1
    fi

    ## WHICH PYTHON VERSION TO USE
    # shellcheck disable=SC2153
    PYTHON="python${PYTHON_VERSION} "
    export PYTHON

    ## WHAT IS THE PIP COMMAND
    PIP_ARGS="install --quiet --upgrade "

    # Add a check to ensure we are on Ubuntu
    if [[ "${OS_NAME}" == "Linux" && -n "${UBUNTU_VER:-}" ]]; then
        if [[ "${UBUNTU_VER}" == "24.04" ]]; then
            PIP_ARGS="install --quiet --upgrade --break-system-packages "
        fi
    fi

    PIP="${PYTHON} -m pip ${PIP_ARGS}"
    export PIP

    # -----------------------------------------------------------------------------
    # ---------------------------------- PYTHON FUNCTIONS -------------------------
    # -----------------------------------------------------------------------------

    # Function to fix old Python issues
    function _Fix_Old_Python() {
        # Fix errors with pyreadline in old Python installations
        if find /usr/local/lib -name "__init__.py" \
            -path "/usr/local/lib/*/pyreadline/keysyms/*" \
            -exec sed -i \
            's/raise ImportError("Could not import keysym for local pythonversion", x)/raise ImportError("Could not import keysym for local pythonversion")/g' \
            {} \;; then
            pass "Successfully fixed pyreadline issue."
            return "${_PASS}"
        else
            fail "Failed to fix pyreadline issue."
            return "${_FAIL}"
        fi
    }

    function _Install_Python() {
         # Ensure version variable is set
         if [[ -z "${PYTHON}" ]]; then
            fail "Python version (${PYTHON_VERSION}) is not specified."
            return "${_FAIL}"
        fi

        # Install Python 3
        if _Install_Python3; then
            pass "Python ${PYTHON_VERSION} installed successfully."
        else
            fail "Failed to install Python ${PYTHON_VERSION}."
            return "${_FAIL}"
        fi
        _Wait_Pid

        ERROR_FLAG=false
        # Install Pip for python3.x
        if _Install_Pip "${PYTHON}"; then
            pass "pip was installed successfully."
        else
            fail "Failed to install pip."
            ERROR_FLAG=true
            #return "$_FAIL"
        fi
        _Wait_Pid

        # Install Pip for python2.7
        if _Install_Pip "python2.7"; then
            pass "pip was installed successfully."
        else
            fail "Failed to install pip."
            ERROR_FLAG=true
            #return "$_FAIL"
        fi
        _Wait_Pid

        # Install Pipx python3.x
        if _Install_Pipx "${PYTHON}"; then
            pass "pipx was installed successfully."
        else
            fail "Failed to install pipx."
            ERROR_FLAG=true
            #return "$_FAIL"
        fi
        _Wait_Pid

        if [[ "${ERROR_FLAG}" = true ]]; then
            fail "Failed to install Python, pip, and/or pipx."
            return "${_FAIL}"
        fi
        return "${_PASS}"
    }

    # Function to install Python 3
    function _Install_Python3() {
        _Pushd "${TOOLS_DIR}" || {
                                   fail "Failed to change directory to ${TOOLS_DIR}."
                                                                                       return "${_FAIL}"
        }

        UBUNTU_VER=$(_Get_Ubuntu_Version)

        # Install Python if requested
        if ${INSTALL_PYTHON}; then
            case "${UBUNTU_VER}" in
                "22.04" | "24.04i" | "24.10")
                    if ! _Apt_Install "python${PYTHON_VERSION}"; then
                        fail "Failed to install Python ${PYTHON_VERSION}."
                        _Popd
                        return "${_FAIL}"
                    fi
                    ;;
                *)
                    fail "Unsupported Ubuntu version: ${UBUNTU_VER}."
                    _Popd
                    return "${_FAIL}"
                    ;;
            esac
            _Popd
            return "${_PASS}"
        fi

        if ${COMPILE_PYTHON}; then
            local LATEST_VER
            LATEST_VER=$(${PROXY} curl -s https://www.python.org/ftp/python/ |
                  grep -oP "href=\"${PYTHON_VERSION}\.[0-9]+/" |
                  sort -u -V |
                  awk -F'"' '{print $2}' |
                  awk -F"/" '{ print $1 }' |
                  tail -n 1)

            # Check if version URL was retrieved
            if [[ -z "${LATEST_VER}" ]]; then
                fail "Failed to determine the latest Python version."
                _Popd
                return "${_FAIL}"
            fi

            # Download, extract, and install Python
            if ! ${PROXY} wget --no-check-certificate "https://www.python.org/ftp/python/${LATEST_VER}/Python-${LATEST_VER}.tgz"; then
                fail "Failed to download Python ${LATEST_VER}."
                _Popd
                return "${_FAIL}"
            fi

            if ! tar -xvf "Python-${LATEST_VER}.tgz"; then
                fail "Failed to extract Python ${LATEST_VER}."
                rm "Python-${LATEST_VER}.tgz"
                _Popd
                return "${_FAIL}"
            fi

            cd "Python-${LATEST_VER}" || {
                                           fail "Failed to change directory to Python-${LATEST_VER}."
                                                                                                       _Popd
                                                                                                              return "${_FAIL}"
            }
            if ! ./configure --enable-optimizations; then
                fail "Configuration of Python ${LATEST_VER} failed."
                cd "${TOOLS_DIR}" || return "${_FAIL}"
                rm -rf "Python-${LATEST_VER}" "Python-${LATEST_VER}.tgz"
                _Popd
                return "${_FAIL}"
            fi

            if ! make -j "$(nproc)"; then
                fail "Build of Python ${LATEST_VER} failed."
                cd "${TOOLS_DIR}" || return "${_FAIL}"
                rm -rf "Python-${LATEST_VER}" "Python-${LATEST_VER}.tgz"
                _Popd
                return "${_FAIL}"
            fi

            if ! make altinstall; then
                fail "Installation of Python ${LATEST_VER} failed."
                cd "${TOOLS_DIR}" || return "${_FAIL}"
                rm -rf "Python-${LATEST_VER}" "Python-${LATEST_VER}.tgz"
                _Popd
                return "${_FAIL}"
            fi

            cd "${TOOLS_DIR}" || return "${_FAIL}"
            rm -rf "Python-${LATEST_VER}" "Python-${LATEST_VER}.tgz"
            pass "Python ${LATEST_VER} installed successfully."
        fi

        _Popd
        return "${_PASS}"
    }

    # Install pip for Python 3.x or Python 2.7
    function _Install_Pip() {
        local python_cmd="${1:-${PYTHON}}"
        local python_version

        # Check if the specified Python command is available
        if ! command -v "${python_cmd}" > /dev/null 2>&1; then
            fail "Python command '${python_cmd}' is not found. Ensure that the specified Python version is installed."
            return "${_FAIL}"
        fi

        # Determine Python version
        python_version=$("${python_cmd}" -c "import sys; print('{}.{}'.format(*sys.version_info[:2]))" 2> /dev/null)
        if [[ -z "${python_version}" ]]; then
            fail "Failed to determine Python version for '${python_cmd}'."
            return "${_FAIL}"
        fi

        info "Detected Python version: ${python_version} for command: ${python_cmd}"

        # Check if pip is already installed
        if "${python_cmd}" -m pip --version > /dev/null 2>&1; then
            pass "pip is already installed for Python ${python_version}."
            return "${_PASS}"
        fi

        info "pip not found for ${python_cmd}. Attempting to install pip..."

        # Attempt to install pip using apt
        if [[ "${python_version}" == 2.7* ]]; then
            info "Installing pip for Python 2.7 using apt..."
            if ! _Apt_Install "python-pip"; then
                fail "Failed to install pip for Python 2.7 using apt."
            fi
        else
            info "Installing pip for Python ${python_version} using apt..."
            if ! _Apt_Install "python3-pip"; then
                fail "Failed to install pip for Python ${python_version} using apt."
            fi
        fi

        # Verify pip installation
        if "${python_cmd}" -m pip --version > /dev/null 2>&1; then
            pass "pip installed successfully for Python ${python_version} using apt."
            return "${_PASS}"
        fi

        warn "pip installation using apt failed or is not available. Falling back to get-pip.py..."

        # Fallback: Install pip using get-pip.py
        local get_pip_url="https://bootstrap.pypa.io/get-pip.py"
        local get_pip_file="get-pip.py"

        # Download get-pip.py
        if ! ${PROXY} _CURL "${get_pip_url}" "${get_pip_file}"; then
            fail "Failed to download get-pip.py for Python ${python_version}."
            return "${_FAIL}"
        fi
        pass "Downloaded get-pip.py for Python ${python_version}."

        # Install pip using get-pip.py
        if ! ${PROXY} "${python_cmd}" "${get_pip_file}"; then
            rm -f "${get_pip_file}"
            fail "Failed to install pip for Python ${python_version} using get-pip.py."
            return "${_FAIL}"
        fi

        # Cleanup and final verification
        rm -f "${get_pip_file}"
        pass "Installed pip for Python ${python_version} using get-pip.py."

        if "${python_cmd}" -m pip --version > /dev/null 2>&1; then
            pass "pip installed successfully for Python ${python_version}."
            return "${_PASS}"
        else
            fail "pip installation for Python ${python_version} failed after using get-pip.py."
            return "${_FAIL}"
        fi
    }

    # Install pipx for Python 3.x
    function _Install_Pipx() {
        # Default to installing pipx for the specified Python version
        local python_cmd="${1:-${PYTHON}}"

        # Check if the specified Python version is installed
        if ! command -v "${python_cmd}" > /dev/null 2>&1; then
            fail "Python command '${python_cmd}' is not found. Ensure that the specified Python version is installed."
            return "${_FAIL}"
        fi

        # Attempt to install pipx using apt if not already installed
        if ! command -v pipx > /dev/null 2>&1; then
            info "Attempting to install pipx using apt..." # should work for Ubuntu >= 23.04
            if ! _Apt_Install "pipx"; then
                fail "Failed to install pipx using apt."
            else
                # Ensure pipx's binary location is in PATH
                _Remove_From_PATH "${HOME}/.local/bin"
                if [[ ":${PATH}:" != *":${HOME}/.local/bin:"* ]]; then
                    export PATH="${PATH}:${HOME}/.local/bin"
                fi

                if ! pipx ensurepath --force; then
                    fail "Failed to ensure pipx's PATH. Check your installation."
                fi

                pipx completions bash >> ~/.bashrc
                eval "$(register-python-argcomplete pipx)"

                # Verify pipx installation
                if command -v pipx > /dev/null 2>&1; then
                    pass "pipx installed successfully using apt."
                    return "${_PASS}"
                else
                    fail "pipx installation failed after using apt."
                fi
            fi
        else
            pass "pipx is already installed."
            return "${_PASS}"
        fi

        # Fallback method: Install pipx using pip if the apt method fails
        info "Attempting to install pipx using pip..." # Needed for Ubuntu < 23.04
        if ! "${python_cmd}" -m pip --version > /dev/null 2>&1; then
            fail "pip is not available for Python command '${python_cmd}'. Install pip before proceeding."
            return "${_FAIL}"
        fi

        if ! "${python_cmd}" -m pip install --user pipx; then
            fail "Failed to install pipx using pip."
            return "${_FAIL}"
        fi

        # Ensure pipx's binary location is in PATH
        _Remove_From_PATH "${HOME}/.local/bin"
        if [[ ":${PATH}:" != *":${HOME}/.local/bin:"* ]]; then
            export PATH="${PATH}:${HOME}/.local/bin"
        fi

        if ! pipx ensurepath --force; then
            fail "Failed to ensure pipx's PATH. Check your installation."
            return "${_FAIL}"
        fi

        pipx completions bash >> ~/.bashrc
        eval "$(register-python-argcomplete pipx)"

        # Verify pipx installation
        if command -v pipx > /dev/null 2>&1; then
            pass "pipx installed successfully using pip."
            return "${_PASS}"
        else
            fail "pipx installation failed after using pip."
            return "${_FAIL}"
        fi
    }

    # Function to install Python libraries for a particular version of python
    function _Pip_Install_Ver() {
        local python_version="$1"
        local lib="$2"
        local PIP_ARGS="$3"

        # Verify that both parameters are provided
        if [[ -z "${python_version}" ]] || [[ -z "${lib}" ]]; then
            fail "Both python_version and library name must be provided."
            return "${_FAIL}"
        fi

        info "Installing ${lib} using python${python_version}..."

        # Attempt to install the library using pip
        if ! PIP_ROOT_USER_ACTION=ignore ${PROXY} python"${python_version}" -m pip "${PIP_ARGS}" "${lib}" --break-system-packages > /dev/null 2>&1; then
            fail "Failed to install ${lib} using python${python_version} -m pip."
            return "${_FAIL}"
        fi

        # Verify that the package is installed
        if ! PIP_ROOT_USER_ACTION=ignore ${PROXY} python"${python_version}" -m pip show "${lib}" > /dev/null 2>&1; then
            fail "${lib} is not installed for python${python_version}. Verification failed."
            return "${_FAIL}"
        fi

        pass "Successfully installed ${lib} using python${python_version}."
        return "${_PASS}"
    }

    # Function to install a Python library using pip
    function _Pip_Install() {
        local lib="$1"
        local USE_PIP_ARGS="${2:-"true"}"

        if [[ "${USE_PIP_ARGS}" = "true" ]]; then
            tmp_PIP_ARGS=${PIP_ARGS}
        else
            tmp_PIP_ARGS="install "
        fi

        # Verify that the library name is provided
        if [[ -z "${lib}" ]]; then
            fail "Library name must be provided."
            return "${_FAIL}"
        fi

        # Call _PipInstallVer with the global python version
        _Pip_Install_Ver "${PYTHON_VERSION}" "${lib}" "${tmp_PIP_ARGS}"
        return "${_PASS}"
    }

    # Function to install Python libraries from a requirements file for a particular version of python
    function _Pip_Install_Requirements_Ver() {
        local python_version="$1"
        local file="$2"
        local PIP_ARGS="$3"

        # Verify that both parameters are provided
        if [[ -z "${python_version}" ]] || [[ -z "${file}" ]]; then
            fail "Both python_version and filename must be provided."
            return "${_FAIL}"
        fi

        info "Installing Python packages from ${file} using python${python_version}..."

        # Attempt to install the libraries using pip
        if ! PIP_ROOT_USER_ACTION=ignore ${PROXY} python"${python_version}" -m pip "${PIP_ARGS}" -r "${file}" > /dev/null 2>&1; then
            fail "Failed to install packages from ${file} using python${python_version} -m pip."
            return "${_FAIL}"
        fi

        # Verify installation of each package listed in the requirements file
        while IFS= read -r package; do
            # Skip comments and empty lines
            [[ "${package}" =~ ^\s*# ]] || [[ -z "${package}" ]] && continue

            # Extract package name (strip version if present)
            local package_name
            package_name=$(echo "${package}" | awk -F'[>=<]' '{print $1}' | xargs)

            # Check if the package is installed
            if ! PIP_ROOT_USER_ACTION=ignore ${PROXY} python"${python_version}" -m pip show "${package_name}" > /dev/null 2>&1; then
                fail "${package_name} from ${file} is not installed for python${python_version}. Verification failed."
                return "${_FAIL}"
            fi
        done < "${file}"

        pass "Successfully installed packages from ${file} using python${python_version}."
        return "${_PASS}"
    }

    # Function to install Python libraries from a requirements file
    function _Pip_Install_Requirements() {
        local file="$1"
        local USE_PIP_ARGS="${2:-"true"}"

        if [[ "${USE_PIP_ARGS}" = "true" ]]; then
            tmp_PIP_ARGS=${PIP_ARGS}
        else
            tmp_PIP_ARGS="install "
        fi

        # Verify that a file name is provided
        if [[ -z "${file}" ]]; then
            fail "Filename name must be provided."
            return "${_FAIL}"
        fi

        # Call _PipInstallRequirementsVer with the global python version
        _Pip_Install_Requirements_Ver "${PYTHON_VERSION}" "${file}" "${tmp_PIP_ARGS}"
        return "${_PASS}"
    }

    # Function to install Python pipx package
    function _Pipx_Install() {
        local package="$1"

        # Ensure package name is provided
        if [[ -z "${package}" ]]; then
            fail "Package name is required for pipx install."
            return "${_FAIL}"
        fi

        info "Installing ${package} using pipx..."
        if ! ${PROXY} pipx install "${package}" --force > /dev/null 2>&1; then
            fail "Failed to install ${package} with pipx."
            return "${_FAIL}"
        fi

        # Verify installation
        if ! pipx list | grep -q "${package}"; then
            fail "${package} was not found in the pipx list. Installation might have failed."
            return "${_FAIL}"
        fi

        pass "Successfully installed ${package} with pipx."
        return "${_PASS}"
    }

    # Function to install Python libraries
    function _Install_Python_Libs() {
        local libs=("${1:-${PIP_PACKAGES[@]}}")  # Use provided parameter or fallback to pip_packages

        # Ensure at least one library is provided
        if [[ ${#libs[@]} -eq 0 ]]; then
            fail "No Python libraries provided for installation."
            ERROR_FLAG=true
        fi

        ERROR_FLAG=false
        # Install each library
        for lib in "${libs[@]}"; do
            if ! _Pip_Install "${lib}"; then
                fail "Failed to install ${lib}."
                ERROR_FLAG=true
            fi

            # Verify installation
            if ! ${PYTHON} -m pip show "${lib}" > /dev/null 2>&1; then
                fail "${lib} is not installed. Verification failed."
                ERROR_FLAG=true
            fi
        done

        # Remove old or unnecessary packages
        if ! ${PROXY} apt remove -y python3-blinker > /dev/null 2>&1; then
            warning "Failed to remove python3-blinker."
        fi

        if [[ "${ERROR_FLAG}" = true ]]; then
            fail "Failed to install all Python Libraries."
            return "${_FAIL}"
        fi
        pass "Successfully installed all Python libraries."
        return "${_PASS}"
    }

    function _Install_Pipx_Tools() {
        local packages=("${1:-${PIPX_PACKAGES[@]}}")  # Use provided parameter or fallback to pipx_packages

        # Ensure at least one package is provided
        if [[ ${#packages[@]} -eq 0 ]]; then
            fail "No pipx packages provided for installation."
            ERROR_FLAG=true
        fi

        ERROR_FLAG=false
        # Install each package listed
        for package in "${packages[@]}"; do
            if ! _Pipx_Install "${package}"; then
                fail "Failed to install ${package} with pipx."
                ERROR_FLAG=true
            fi
        done

        if [[ "${ERROR_FLAG}" = true ]]; then
            fail "Failed to install all pipx tools."
            return "${_FAIL}"
        fi
        pass "Successfully installed all pipx tools."
        return "${_PASS}"
    }
fi
