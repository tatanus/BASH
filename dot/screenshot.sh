#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : screenshot.sh
# DESCRIPTION : Capture command or text output and save as a PNG file.
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-08 19:57:22
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-08 19:57:22  | Adam Compton | Initial creation.
# =============================================================================

# Guard to prevent multiple sourcing
if [[ -z "${SCREENSHOT_SH_LOADED:-}" ]]; then
    declare -g SCREENSHOT_SH_LOADED=true

    # =============================================================================
    # Helper Functions
    # =============================================================================

    # Function to verify required tools are available
    function check_required_screenshot_tools() {
        for cmd in ansifilter a2ps convert; do
            if ! command -v "${cmd}" &>/dev/null; then
                echo "Error: Required tool '${cmd}' is not installed or not in PATH." >&2
                return 1
            fi
        done
    }

    # Function to process input (text or command output) and generate a PNG
    function generate_screenshot_png() {
        local input="$1"
        local output_file="$2"
        local temp_html_file
        local temp_ps_file

        # Create temporary files
        temp_html_file=$(mktemp)
        temp_ps_file=$(mktemp)

        # Process the input through ansifilter
        echo "${input}" | ansifilter --html >"${temp_html_file}"  2>/dev/null
        if [[ $? -ne 0 ]]; then
            echo "Error: Failed to process input with ansifilter." >&2
            rm -f "${temp_html_file}" "${temp_ps_file}"
            return 1
        fi

        # Convert HTML to PostScript using a2ps
        a2ps --no-header "${temp_html_file}" -o "${temp_ps_file}" >/dev/null  2>&1
        if [[ $? -ne 0 ]]; then
            echo "Error: Failed to convert HTML to PostScript using a2ps." >&2
            rm -f "${temp_html_file}" "${temp_ps_file}"
            return 1
        fi

        # Convert PostScript to PNG using ImageMagick's convert
        convert -density 300 "${temp_ps_file}" -quality 100 "${output_file}" >/dev/null  2>&1
        if [[ $? -ne 0 ]]; then
            echo "Error: Failed to convert PostScript to PNG using ImageMagick's convert." >&2
            rm -f "${temp_html_file}" "${temp_ps_file}"
            return 1
        fi

        # Clean up temporary files
        rm -f "${temp_html_file}" "${temp_ps_file}"

        echo "Success: Output has been saved to '${output_file}'."
        return 0
    }

    # =============================================================================
    # Main Functions
    # =============================================================================

    # Function to capture command output and save it as a PNG file
    function screenshot_command() {
        local output_file="${2:-output.png}"  # Default output file name is "output.png"

        # Check if required tools are available
        check_required_screenshot_tools || return 1

        # Verify that a command to capture has been provided
        if [[ -z "$1" ]]; then
            echo "Usage: screenshot_command '<command>' [output_file]" >&2
            echo "Example: screenshot_command 'ls --color' output.png" >&2
            return 1
        fi

        # Execute the command and capture its output
        local command_output
        command_output=$(eval "$1" 2>/dev/null)
        if [[ $? -ne 0 ]]; then
            echo "Error: Failed to execute command: $1" >&2
            return 1
        fi

        # Generate PNG from the command output
        generate_screenshot_png "${command_output}" "${output_file}"
    }

    # Function to capture text output and save it as a PNG file
    function screenshot_text() {
        local output_file="${2:-output.png}"  # Default output file name is "output.png"

        # Check if required tools are available
        check_required_screenshot_tools || return 1

        # Verify that input text is provided
        if [[ -z "$1" ]]; then
            echo "Usage: screenshot_text '<text>' [output_file]" >&2
            echo "Example: screenshot_text 'Hello World' output.png" >&2
            return 1
        fi

        # Generate PNG from the provided text
        generate_screenshot_png "$1" "${output_file}"
    }
fi
