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

    # Add an alias to the alias file
    function _Add_Alias() {
        local alias_entry="$*"

        # Verify that PENTEST_ALIAS_FILE is set and writable
        if [[ -z "${PENTEST_ALIAS_FILE}" ]]; then
            info "${alias_entry}"
            fail "PENTEST_ALIAS_FILE is not set. Cannot add alias."
            return "${_FAIL}"
        fi

        if [[ ! -w "${PENTEST_ALIAS_FILE}" ]]; then
            info "${alias_entry}"
            fail "ALIAS_FILE (${PENTEST_ALIAS_FILE}) is not writable."
            return "${_FAIL}"
        fi

        # Append the alias entry to the alias file
        echo "${alias_entry}" >> "${PENTEST_ALIAS_FILE}"
        pass "Added alias: ${alias_entry}"
        return "${_PASS}"
    }

    # Delete an alias from the alias file
    function _Del_Alias() {
        local alias_name="$1"

        # Validate inputs
        if [[ -z "${alias_name}" ]] || [[ -z "${PENTEST_ALIAS_FILE}" ]]; then
            fail "Usage: _DelAlias <alias_name>"
            return "${_FAIL}"
        fi

        # Check if the alias exists
        if ! alias "${alias_name}" &> /dev/null; then
            info "Alias ${alias_name} does not exist."
            return "${_FAIL}"
        fi

        # Unalias the alias
        unalias "${alias_name}" 2> /dev/null

        # Remove lines containing the alias from the alias file
        sed -i "/^alias ${alias_name}=/d" "${PENTEST_ALIAS_FILE}"

        # Verify the alias has been removed
        if grep -q "^alias ${alias_name}=" "${PENTEST_ALIAS_FILE}"; then
            fail "Failed to remove alias ${alias_name}."
            return "${_FAIL}"
        else
            pass "Alias ${alias_name} removed successfully."
            return "${_PASS}"
        fi
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
        for PACKAGE in "${PIP_INSTALLS[@]}"; do
            if [[ "${PACKAGE}" == "." ]]; then
                if ! _Pip_Install "${TOOLS_DIR}/${DIRECTORY_NAME}/." ""; then
                    fail "Failed to install package: ${TOOLS_DIR}/${DIRECTORY_NAME}/."
                    deactivate
                    _Popd
                    fail "Failed to install ${DIRECTORY_NAME}"
                else
                    info "Installed package ${PACKAGE}"
                fi
            else
                if ! _Pip_Install "${PACKAGE}" ""; then
                    fail "Failed to install package: ${PACKAGE}"
                    deactivate
                    _Popd
                    fail "Failed to install ${DIRECTORY_NAME}"
                else
                    info "Installed package ${PACKAGE}"
                fi
            fi
        done

        deactivate
        _Add_Alias "alias ${TOOL_NAME}.py='pushd ${TOOLS_DIR}/${DIRECTORY_NAME}/  >/dev/null && ${TOOLS_DIR}/${DIRECTORY_NAME}/venv/bin/${PYTHON} ${TOOLS_DIR}/${DIRECTORY_NAME}/${TOOL_NAME}.py && popd >/dev/null'"
        _Add_Alias "alias ${TOOL_NAME}='pushd ${TOOLS_DIR}/${DIRECTORY_NAME}/  >/dev/null && ${TOOLS_DIR}/${DIRECTORY_NAME}/venv/bin/${PYTHON} ${TOOLS_DIR}/${DIRECTORY_NAME}/${TOOL_NAME}.py && popd >/dev/null'"

        _Popd
        pass "${DIRECTORY_NAME} installed and virtual environment set up successfully."
    }

    function AppTest() {
        # Ensure aliases are expanded in non-interactive scripts
        shopt -s expand_aliases

        local appName="$1"
        local appCommand="$2"

        # Execute the command and capture output and exit status
        local output
        output=$(eval "${appCommand}" 2>&1)
        local status=$?

        # Check if the command was successful or if specific conditions are met
        if [[ "${status}" -eq 0 ]]; then
            pass "SUCCESS: [${appName}] - [${appCommand}]"
        elif { [[ "${appName}" = "aquatone" ]] || [[ "${appName}" = "pretender" ]]; } && [[ "${status}" -eq 2 ]]; then
            pass "SUCCESS: [${appName}] - [${appCommand}] - Exit Status [${status}]"
        else
            fail "FAILED : [${appName}] - [${appCommand}] - Exit Status [${status}]"
        fi

        # Return a non-zero status if the command failed
        return "${status}"
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

fi
