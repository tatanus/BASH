#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : renew_tgt.sh
# DESCRIPTION : Script to renew Kerberos Ticket Granting Tickets (TGTs) stored
#               in ccache files for easier management.
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-08 20:11:12
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-08 20:11:12  | Adam Compton | Initial creation.
# =============================================================================

# Guard to prevent multiple sourcing
if [[ -z "${RENEW_TGT_LOADED:-}" ]]; then
    declare -g RENEW_TGT_LOADED=true

    # =============================================================================
    # Function: renewTGT
    # Description:
    #   Renews a Kerberos Ticket Granting Ticket (TGT) using a specified ccache file.
    # Parameters:
    #   $1 - Path to the ccache file.
    # Returns:
    #   0 on success, 1 on failure.
    # =============================================================================
    renewTGT() {
        if [[ $# -ne 1 ]]; then
            echo "Error: Missing required argument."
            echo "Usage: renewTGT <ccache>"
            return 1
        fi

        local ccache="$1"

        # Verify that the ccache file exists
        if [[ ! -f "${ccache}" ]]; then
            echo "Error: ccache file '${ccache}' not found."
            return 1
        fi

        # Attempt to renew the TGT using available tools
        if [[ -x "/usr/local/bin/renewTGT.py" ]]; then
            echo "Using /usr/local/bin/renewTGT.py to renew ${ccache}."
            KRB5CCNAME="${ccache}" /usr/local/bin/renewTGT.py -k
        elif [[ -x "${HOME}/.local/bin/renewTGT.py" ]]; then
            echo "Using ${HOME}/.local/bin/renewTGT.py to renew ${ccache}."
            KRB5CCNAME="${ccache}" "${HOME}/.local/bin/renewTGT.py" -k
        else
            echo "Using kinit to renew ${ccache}."
            KRB5CCNAME="${ccache}" kinit -R -r7d
        fi

        if [[ $? -eq 0 ]]; then
            echo "Successfully renewed TGT for ${ccache}."
        else
            echo "Failed to renew TGT for ${ccache}."
            return 1
        fi
    }

    # =============================================================================
    # Function: renewAllTGT
    # Description:
    #   Renews all Kerberos Ticket Granting Tickets (TGTs) in the
    #   $ENGAGEMENT_DIR/LOOT/CREDENTIALS/CCACHE directory.
    # Returns:
    #   0 on success, 1 if no ccache files are found or an error occurs.
    # =============================================================================
    renewAllTGT() {
        local tgt_dir="${ENGAGEMENT_DIR}/LOOT/CREDENTIALS/CCACHE"

        # Verify that the TGT directory exists
        if [[ ! -d "${tgt_dir}" ]]; then
            echo "Error: TGT directory '${tgt_dir}' not found."
            return 1
        fi

        # List all .ccache files in the directory
        local ccache_files=("${tgt_dir}"/*.ccache)
        if [[ ${#ccache_files[@]} -eq 1 && ! -f "${ccache_files[0]}" ]]; then
            echo "No TGT files found in ${tgt_dir}."
            return 1
        fi

        # Renew each TGT file
        echo "Renewing TGTs for ccache files in ${tgt_dir}..."
        for tgt_file in "${ccache_files[@]}"; do
            echo "Processing ${tgt_file}..."
            renewTGT "${tgt_file}" || echo "Warning: Failed to renew TGT for ${tgt_file}."
        done
    }

    # Automatically renew all TGTs when the script is sourced or executed
    renewAllTGT
fi
