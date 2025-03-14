#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : tgt.aliases.sh
# DESCRIPTION : Helper functions for managing Kerberos Ticket Granting Tickets (TGTs)
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-08 19:57:22
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-08 19:57:22  | Adam Compton | Initial creation.
# =============================================================================

# Guard to prevent multiple sourcing
if [[ -z "${TGT_ALIAS_SH_LOADED:-}" ]]; then
    declare -g TGT_ALIAS_SH_LOADED=true

    # Default directory for TGT files
    TGT_DIR="${ENGAGEMENT_DIR}/LOOT/CREDENTIALS/CCACHE"

    # Ensure the TGT directory exists
    if [[ ! -d "${TGT_DIR}" ]]; then
        echo "Creating TGT directory: ${TGT_DIR}"
        mkdir -p "${TGT_DIR}" || {
            echo "Error: Unable to create TGT directory."
            return 1
        }
    fi

    # =============================================================================
    # Function: getTGT
    # Description:
    #   Obtains a Ticket Granting Ticket (TGT) using getTGT.py.
    # Parameters:
    #   $1 - Arguments for getTGT.py.
    # Returns:
    #   0 on success, 1 on failure.
    # =============================================================================
    function getTGT() {
        if [[ $# -lt 3 ]]; then
            echo "Usage: getTGT <domain>/<username>:<password> -dc-ip <dc> -or- <domain>/<username> -hashes <ntlm> -dc-ip <dc>"
            return 1
        fi

        local args="$*"
        local output
        # shellcheck disable=SC2086
        output=$(getTGT.py ${args} 2>&1)

        if [[ $? -ne 0 ]]; then
            echo "Error: Failed to obtain TGT. Details:"
            echo "${output}"
            return 1
        fi

        local filename
        filename=$(echo "${output}" | grep "Saving ticket in" | awk '{print $NF}')

        if [[ -z "${filename}" ]]; then
            echo "Error: TGT file was not created or path could not be determined."
            return 1
        fi

        saveTGT "${filename}"
    }

    # =============================================================================
    # Function: saveTGT
    # Description:
    #   Saves a TGT (ccache) file to the specified directory.
    # Parameters:
    #   $1 - Path to the TGT file to save.
    # Returns:
    #   0 on success, 1 on failure.
    # =============================================================================
    function saveTGT() {
        if [[ $# -ne 1 ]]; then
            echo "Usage: saveTGT <file>"
            return 1
        fi

        local tgt_file="$1"
        local tgt_filename
        tgt_filename=$(basename "${tgt_file}")

        if [[ ! -f "${tgt_file}" ]]; then
            echo "Error: TGT file '${tgt_file}' does not exist."
            return 1
        fi

        if [[ ! -f "${TGT_DIR}/${tgt_filename}" ]]; then
            cp "${tgt_file}" "${TGT_DIR}/${tgt_filename}"
        else
            local i=1
            while [[ -f "${TGT_DIR}/${tgt_filename%.*}-${i}.${tgt_filename##*.}" ]]; do
                ((i++))
            done
            cp "${tgt_file}" "${TGT_DIR}/${tgt_filename%.*}-${i}.${tgt_filename##*.}"
        fi

        echo "TGT file saved to ${TGT_DIR}."
    }

    # =============================================================================
    # Function: listTGT
    # Description:
    #   Lists TGT files in the specified directory and allows exporting via fzf.
    # =============================================================================
    function listTGT() {
        if [[ ! -d "${TGT_DIR}" ]]; then
            echo "Error: TGT directory does not exist."
            return 1
        fi

        local ccache_files=("${TGT_DIR}"/*.ccache)
        if [[ ${#ccache_files[@]} -eq 0 ]]; then
            echo "No TGT files found in ${TGT_DIR}."
            return 1
        fi

        local tgt_choices=()
        for tgt_file in "${ccache_files[@]}"; do
            local filename
            filename=$(basename "${tgt_file}")
            local validity
            validity=$(validateTGT "${tgt_file}" | cut -d ' ' -f 2-)
            tgt_choices+=("$(printf "%-40s - %-40s" "${filename}" "${validity}")")
        done

        echo -ne "\033]0;Choose a TGT file\007"
        local selected_tgt
        selected_tgt=$(printf "%s\n" "${tgt_choices[@]}" | fzf --prompt="Choose a TGT file: " --no-clear)
        echo -ne "\033]0;\007"

        local selected_filename
        selected_filename=$(echo "${selected_tgt}" | awk '{print $1}')

        for tgt_file in "${ccache_files[@]}"; do
            if [[ "${tgt_file}" == *"${selected_filename}"* ]]; then
                exportTGT "${tgt_file}"
                echo "${tgt_file} exported to KRB5CCNAME"
                return 0
            fi
        done

        echo "Invalid choice."
        return 1
    }

    # =============================================================================
    # Function: validateTGT
    # Description:
    #   Validates a TGT file and checks its expiration time.
    # =============================================================================
    function validateTGT() {
        if [[ $# -ne 1 ]]; then
            echo "Usage: validateTGT <file>"
            return 1
        fi

        local tgt_file="$1"

        if [[ ! -f "${tgt_file}" ]]; then
            echo "Error: File '${tgt_file}' does not exist."
            return 1
        fi

        local end_time
        end_time=$(KRB5CCNAME="${tgt_file}" klist -A 2> /dev/null | grep "krbtgt" | awk '{print $3, $4}')
        if [[ -z "${end_time}" ]]; then
            echo "${tgt_file}: Expired"
            return 1
        fi

        echo "${tgt_file}: Valid (Expires: ${end_time})"
    }

    # # Function to validate a single TGT file
    # function validateTGT() {
    #     local tgt_file="$1"

    #     # Check if file exists
    #     if [[ ! -f "${tgt_file}" ]]; then
    #         echo "File '${tgt_file}' does not exist."
    #         return 1
    #     fi

    #     local end_time_value

    #     end_time_value=$(KRB5CCNAME="${tgt_file}" klist -A 2> /dev/null | grep "krbtgt" | awk '{print $3, $4}')

    #     # Check if end time value is empty
    #     if [[ -z ${end_time_value} ]]; then
    #         echo "Failed to retrieve end time for '${tgt_file}'."
    #         return 1
    #     fi

    #     # Convert end time to timestamp
    #     local end_time_formatted_value
    #     end_time_formatted_value=$(echo "${end_time_value}" | sed -E 's#^([0-9]{2})/([0-9]{2})/([0-9]{4}) ([0-9]{2}:[0-9]{2}:[0-9]{2}) (AM|PM)$#\2/\1/\3 \4#' 2> /dev/null)
    #     local end_time_timestamp
    #     end_time_timestamp=$(date -d "${end_time_formatted_value}" +%s 2> /dev/null)

    #     # Check if date conversion failed
    #     if [[ $? -ne 0 ]]; then
    #         echo "Failed to convert end time to timestamp for '${tgt_file}'."
    #         return 1
    #     fi

    #     local current_timestamp
    #     current_timestamp=$(date +%s)

    #     # Compare end time with current time
    #     if [[ ${end_time_timestamp} -gt ${current_timestamp} ]]; then
    #         local remaining_seconds=$((end_time_timestamp - current_timestamp))
    #         local remaining_hours=$((remaining_seconds / 3600))
    #         local remaining_minutes=$((remaining_seconds % 3600 / 60))
    #         local remaining_seconds=$((remaining_seconds % 60))
    #         echo "${tgt_file}: Valid (Expires in ${remaining_hours} hours, ${remaining_minutes} minutes, ${remaining_seconds} seconds)"
    #     else
    #         echo "${tgt_file}: Expired"
    #     fi
    # }

    # Function to export a TGT file
    function exportTGT() {
        # Check the number of arguments
        # Usage: exportTGT <full_path_and_filename>
        if [[ $# -ne 1 ]]; then
            echo "Usage: exportTGT <full_path_and_filename>"
            return 1
        fi

        export KRB5CCNAME="$1"
    }

    # Function to renew a TGT
    function renewTGT() {
        # Check the number of arguments
        # Usage: renewTGT <ccache>
        if [[ $# -ne 1 ]]; then
            echo "Usage: renewTGT <ccache>"
            return 1
        fi

        local ccache="$1"

        if [[ -x "/usr/local/bin/renewTGT.py" ]]; then
            KRB5CCNAME="${ccache}" /usr/local/bin/renewTGT.py -k
        elif [[ -x "/root/.local/bin/renewTGT.py" ]]; then
            KRB5CCNAME="${ccache}" /root/.local/bin/renewTGT.py -k
        else
            KRB5CCNAME="${ccache}" kinit -R -r7d
        fi
    }

    # Function to renew all TGT files in ~/.ccache
    function renewAllTGT() {
        # Check if directory exists
        if [[ ! -d "${TGT_DIR}" ]]; then
            echo "No TGT files found."
            return 1
        fi

        # List .ccache files in the directory
        local ccache_files=("${TGT_DIR}"/*.ccache)
        if [[ ${#ccache_files[@]} -eq 0 ]]; then
            echo "No TGT files found in ${TGT_DIR}."
            return 1
        fi

        # renew each TGT file
        for tgt_file in "${ccache_files[@]}"; do
            if [[ $# -ne 1 ]]; then
                renewTGT "${tgt_file}"
            else
                renewTGT "${tgt_file}" "$1"
            fi
        done
    }

    # Function to test TGT files against a domain controller
    function testTGTs() {
        # Check the number of arguments
        # Usage: textTGTs <dc-ip>
        if [[ $# -ne 1 ]]; then
            echo "Usage: textTGTs <dc-ip>"
            return 1
        fi

        local dc_ip="$1"

        # Check if directory exists
        if [[ ! -d "${TGT_DIR}" ]]; then
            echo "No TGT files found."
            return 1
        fi

        # List .ccache files in the directory
        local ccache_files=("${TGT_DIR}"/*.ccache)
        if [[ ${#ccache_files[@]} -eq 0 ]]; then
            echo "No TGT files found in ${TGT_DIR}."
            return 1
        fi

        # Validate each TGT file
        for tgt_file in "${ccache_files[@]}"; do
            echo "${tgt_file}"
            export KRB5CCNAME="${tgt_file}"
            #nxc smb $dc_ip --use-kcache
        done
    }

    # Function to validate all TGT files in ~/.ccache
    function validateAllTGT() {
        # Check if directory exists
        if [[ ! -d "${TGT_DIR}" ]]; then
            echo "No TGT files found."
            return 1
        fi

        # List .ccache files in the directory
        local ccache_files=("${TGT_DIR}"/*.ccache)
        if [[ ${#ccache_files[@]} -eq 0 ]]; then
            echo "No TGT files found in ${TGT_DIR}."
            return 1
        fi

        # Validate each TGT file
        for tgt_file in "${ccache_files[@]}"; do
            validateTGT "${tgt_file}"
        done
    }
fi
