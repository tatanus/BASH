#!/usr/bin/env bash

# =============================================================================
# NAME        : renew_tgt.sh
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
if [[ -z "${RENEW_TGT_LOADED:-}" ]]; then
    declare -g RENEW_TGT_LOADED=true

    # Function to renew a TGT
    renewTGT() {
        if [[ $# -ne 1 ]]; then
            echo "Usage: renewTGT <ccache>"
            return 1
        fi

        local ccache="$1"

        if [[ -x "/usr/local/bin/renewTGT.py" ]]; then
            KRB5CCNAME="$ccache" /usr/local/bin/renewTGT.py -k
        elif [[ -x "/root/.local/bin/renewTGT.py" ]]; then
            KRB5CCNAME="$ccache" /root/.local/bin/renewTGT.py -k
        else
            KRB5CCNAME="$ccache" kinit -R -r7d
        fi
    }

    # Function to renew all TGT files in ~/.ccache
    renewAllTGT() {
        local tgt_dir="/root/.ccache"

        # Check if directory exists
        if [[ ! -d "$tgt_dir" ]]; then
            echo "No TGT files found."
            return 1
        fi

        # List .ccache files in the directory
        local ccache_files=("$tgt_dir"/*.ccache)
        if [[ ${#ccache_files[@]} -eq 0 ]]; then
            echo "No TGT files found in $tgt_dir."
            return 1
        fi

        # renew each TGT file
        for tgt_file in "${ccache_files[@]}"; do
            renewTGT "$tgt_file"
        done
    }

    renewAllTGT
fi