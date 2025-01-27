#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : utils_tools.sh
# DESCRIPTION :
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-10 12:29:41
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-10 12:29:41  | Adam Compton | Initial creation.
# =============================================================================

# Guard to prevent multiple sourcing
if [[ -z "${UTILS_TOOLS_SH_LOADED:-}" ]]; then
    declare -g UTILS_TOOLS_SH_LOADED=true

    # -----------------------------------------------------------------------------
    # ---------------------------------- INSTALL TOOLS FUNCTIONS ------------------
    # -----------------------------------------------------------------------------

    # add a new function to pentest.alias.sh
    function _add_tool_function() {
        local function_name="$1"
        local tool_path="$2"

        # Verify that PENTEST_ALIAS_FILE is set and writable
        if [[ -z "${PENTEST_ALIAS_FILE}" ]]; then
            fail "PENTEST_ALIAS_FILE is not set. Cannot add alias."
            return "${_FAIL}"
        fi

        if [[ ! -w "${PENTEST_ALIAS_FILE}" ]]; then
            fail "ALIAS_FILE (${PENTEST_ALIAS_FILE}) is not writable."
            return "${_FAIL}"
        fi

        # Validate inputs
        if [[ -z "${function_name}" || -z "${tool_path}" ]]; then
            fail "Usage: _add_tool_function <function_name> <tool_path>" >&2
            return "${_FAIL}"
        fi

        # Check if the function already exists in the alias file
        if grep -qE "^function ${function_name}\s*\(\)\s*{" "${PENTEST_ALIAS_FILE}"; then
            fail "Function '${function_name}' already exists in ${PENTEST_ALIAS_FILE}." >&2
            return "${_FAIL}"
        fi

        # Append the function to the alias file
        {
            echo "function ${function_name}() {"
            echo "    run_tools_command \"\${TOOLS_DIR}/${tool_path}\" \"\$@\";"
            echo "}"
        } >> "${PENTEST_ALIAS_FILE}"

        # Confirm the function was added
        if grep -qE "^function ${function_name}\s*\(\)\s*{" "${PENTEST_ALIAS_FILE}"; then
            pass "Added alias: ${function_name}"
            return "${_PASS}"
        else
            fail "Failed to add alias: ${function_name}" >&2
            return "${_FAIL}"
        fi
    }

    # Add a new function to the pentest.alias.sh file
    _del_tool_function() {
        local function_name="$1"

        # Validate inputs
        if [[ -z "${function_name}" || -z "${file_path}" ]]; then
            fail " Usage: remove_function <function_name> <file_path>" >&2
            return "${_FAIL}"
        fi

        # Verify that PENTEST_ALIAS_FILE is set and writable
        if [[ -z "${PENTEST_ALIAS_FILE}" ]]; then
            fail "PENTEST_ALIAS_FILE is not set. Cannot add alias."
            return "${_FAIL}"
        fi

        if [[ ! -w "${PENTEST_ALIAS_FILE}" ]]; then
            fail "ALIAS_FILE (${PENTEST_ALIAS_FILE}) is not writable."
            return "${_FAIL}"
        fi

        # Check if the function exists in the file
        if ! grep -qE "^${function_name}\s*\(\)\s*{" "${PENTEST_ALIAS_FILE}"; then
            fail "Function '${function_name}' not found in '${PENTEST_ALIAS_FILE}'." >&2
            return "${_FAIL}"
        fi

        # Use sed to remove the exact function definition
        sed -i.bak -E "/^${function_name}\s*\(\)\s*{/ {
            N
            :loop
            /\}/! {N; b loop}
            d
        }" "${file_path}"

        # Check if the removal was successful
        if grep -qE "^${function_name}\s*\(\)\s*{" "${PENTEST_ALIAS_FILE}"; then
            fail "Failed to remove function '${function_name}' from '${PENTEST_ALIAS_FILE}'." >&2
            return "${_FAIL}"
        fi

        info "Function '${function_name}' successfully removed from '${PENTEST_ALIAS_FILE}'."
        return "${_PASS}"
    }

    function _Install_Git_Python_Tool() {
        local TOOL_NAME="$1"
        local GIT_URL="$2"
        local INSTALL_IMPACKET="$3"
        local REQUIREMENTS_FILE="$4"
        shift 4
        local PIP_INSTALLS=("$@")

        # Determine DIRECTORY_NAME from GIT_URL
        local DIRECTORY_NAME="${GIT_URL}"

        # Remove .git suffix if it exists
        if [[ "${DIRECTORY_NAME}" == *.git ]]; then
            DIRECTORY_NAME=${DIRECTORY_NAME%.git}
        fi

        # remove everything  except after the last \
        DIRECTORY_NAME="${DIRECTORY_NAME##*/}"

        # Clone the Git repository
        if ! _Git_Clone "${GIT_URL}"; then
            fail "Failed to clone repository from ${GIT_URL}."
            return "${_FAIL}"
        else
            pass "git cloned"
        fi

        _Pushd "${TOOLS_DIR}/${DIRECTORY_NAME}"

        # Create a virtual environment and install requirements
        if ! ${PYTHON} -m venv ./venv; then
            fail "Failed to create virtual environment."
            _Popd
            return "${_FAIL}"
        else
            pass "Created virtual env"
        fi

        source ./venv/bin/activate

        # Install Impacket if the flag is set
        if [[ "${INSTALL_IMPACKET}" = "true" ]]; then
            Install_Impacket || {
                fail "Failed to install Impacket."
                deactivate
                _Popd
                return "${_FAIL}"
            }
        fi

        # Install requirements if a requirements file is provided
        if [[ -n "${REQUIREMENTS_FILE}" ]] && [[ -f "${REQUIREMENTS_FILE}" ]]; then
            if ! _Pip_Install_Requirements "${REQUIREMENTS_FILE}" ""; then
                fail "Failed to install requirements from ${REQUIREMENTS_FILE}."
                deactivate
                _Popd
                return "${_FAIL}"
            fi
        fi

        # Install additional pip packages if provided
        if [[ ${#PIP_INSTALLS[@]} -gt 0 ]]; then
            for PACKAGE in "${PIP_INSTALLS[@]}"; do
                if [[ "${PACKAGE}" == "." ]]; then
                    if ! _Pip_Install "${TOOLS_DIR}/${DIRECTORY_NAME}/." ""; then
                        fail "Failed to install package: ${TOOLS_DIR}/${DIRECTORY_NAME}/."
                        deactivate
                        _Popd
                        fail "Failed to install ${DIRECTORY_NAME}"
                        return "${_FAIL}"
                    else
                        info "Installed package ${PACKAGE}"
                    fi
                else
                    if ! _Pip_Install "${PACKAGE}" ""; then
                        fail "Failed to install package: ${PACKAGE}"
                        deactivate
                        _Popd
                        fail "Failed to install ${DIRECTORY_NAME}"
                        return "${_FAIL}"
                    else
                        info "Installed package ${PACKAGE}"
                    fi
                fi
            done
        fi

        deactivate

        _add_tool_function "${TOOL_NAME}" "${DIRECTORY_NAME}/${TOOL_NAME}"

        _Popd
        pass "${DIRECTORY_NAME} installed and virtual environment set up successfully."
    }

    function RunAppTest() {
        # Ensure aliases are expanded in non-interactive scripts
        shopt -s expand_aliases

        local appName="$1"
        local appCommand="$2"
        local successExitCode="${3:-0}"

        # Execute the command and capture output and exit status
        local output
        output=$(eval "${appCommand}" 2>&1)
        local status=$?

        # Check if the command was successful or if specific conditions are met
        if [[ "${status}" -eq "${successExitCode}" ]]; then
            return 0  # Indicate success
        else
            return "${status}"  # Indicate failure
        fi
    }

    function AppTest() {
        local appName="$1"
        local appCommand="$2"
        local successExitCode="${3:-0}"

        # Call the test function and handle the result
        if RunAppTest "${appName}" "${appCommand}" "${successExitCode}"; then
            pass "SUCCESS: [${appName}] - [${appCommand}]"
            return 0
        else
            local status=$?
            fail "FAILED : [${appName}] - [${appCommand}] - Exit Status [${status}]"
            return "${status}"  # Return the failure status
        fi
    }

    function _Test_Tool_Installs()  {
        # Ensure all of the aliases are loaded
        source "${PENTEST_ALIAS_FILE}"

        # Initialize counters
        local total_tests=0
        local failed_tests=0

        # Get a sorted list of keys (app names) in ascending alphabetical order, ignoring case
        local sorted_keys=()
        mapfile -t sorted_keys < <(for key in "${!APP_TESTS[@]}"; do echo "${key}"; done | sort -f)

        # Loop over the sorted keys and run each AppTest
        for app_name in "${sorted_keys[@]}"; do
            local command="${APP_TESTS[${app_name}]}"

            AppTest "${app_name}" "${command}"
            local status=$?  # Capture the exit status immediately

            ((total_tests++))

            # Check the exit status of the last executed command
            if [[ "${status}" -ne 0 ]]; then
                ((failed_tests++))
            fi
        done

        # load list of tools from the tools/modules directory
        MODULES_DIR="${SCRIPT_DIR}/tools/modules"

        # Dynamically add tool names from scripts in MODULES_DIR
        if [[ -d "${MODULES_DIR}" ]]; then
            for script in "${MODULES_DIR}"/*.sh; do
                source "${script}" || warn "Failed to source ${script}."

                if [[ -f "${script}" ]]; then
                    tool_name=$(basename "${script}" .sh) # Extract the tool name

                    "test_${tool_name}"
                    local status=$?  # Capture the exit status immediately

                    ((total_tests++))

                    # Check the exit status of the last executed command
                    if [[ "${status}" -ne 0 ]]; then
                        ((failed_tests++))
                    fi
                fi
            done
        else
            warn "Directory not found: ${MODULES_DIR}"
        fi

        # Print summary of results
        warning "Test Summary: ${total_tests} tests ran, ${failed_tests} failed."

        # Pause so the user can read the output
        _Pause
    }

    # Generalized package installation function
    function _install_package() {
        local package_name="$1"

        if [[ -z "${package_name}" ]]; then
            fail "Package name is required for installation."
            return "${_FAIL}"
        fi

        info "Installing ${package_name} for ${OS_NAME}..."

        case "${OS_NAME}" in
            Linux)
                if [[ -n "${UBUNTU_VER}" ]]; then
                    _Apt_Install "${package_name}"
                    return $?
                else
                    fail "Unsupported Linux distribution. Please install ${package_name} manually."
                    return "${_FAIL}"
                fi
                ;;
            Darwin)
                _brew_install "${package_name}"
                return $?
                ;;
            CYGWIN* | MINGW* | MSYS* | Windows_NT)
                fail "Automatic installation for ${package_name} on Windows is not supported. Please install it manually."
                return "${_FAIL}"
                ;;
            *)
                fail "Unsupported operating system: ${OS_NAME}. Please install ${package_name} manually."
                return "${_FAIL}"
                ;;
        esac
    }
fi
