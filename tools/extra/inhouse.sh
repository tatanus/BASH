#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# NAME        : inhouse.sh
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
if [[ -z "${INHOUSE_SH_LOADED:-}" ]]; then
    declare -g INHOUSE_SH_LOADED=true

    src_dir="${SCRIPT_DIR}/tools/extra"

    # Move autoTGT tool
    if [[ -d "${src_dir}/autoTGT" ]]; then
        if mv "${src_dir}/autoTGT" "${TOOLS_DIR}/"; then
            pass "Moved autoTGT to ${TOOLS_DIR}/"
        else
            fail "Failed to move autoTGT to ${TOOLS_DIR}/"
        fi
    else
        fail "Source directory [${src_dir}/autoTGT] does not exist. Skipping."
    fi

    # Move and set up Impacket tool
    if [[ -d "${src_dir}/impacket" ]]; then
        if mv "${src_dir}/impacket" "${TOOLS_DIR}/"; then
            pass "Moved impacket to ${TOOLS_DIR}/"
            Install_Impacket
        else
            fail "Failed to move impacket to ${TOOLS_DIR}/"
        fi
    else
        fail "Source directory [${src_dir}/impacket] does not exist. Skipping."
    fi

    # Move packedcollection tool
    if [[ -d "${src_dir}/packedcollection" ]]; then
        if mv "${src_dir}/packedcollection" "${TOOLS_DIR}/"; then
            pass "Moved packedcollection to ${TOOLS_DIR}/"
        else
            fail "Failed to move packedcollection to ${TOOLS_DIR}/"
        fi
    else
        fail "Source directory [${src_dir}/packedcollection] does not exist. Skipping."
    fi

    # Move precompiled-offensive-bins tool
    if [[ -d "${src_dir}/precompiled-offensive-bins" ]]; then
        if mv "${src_dir}/precompiled-offensive-bins" "${TOOLS_DIR}/"; then
            pass "Moved precompiled-offensive-bins to ${TOOLS_DIR}/"
        else
            fail "Failed to move precompiled-offensive-bins to ${TOOLS_DIR}/"
        fi
    else
        fail "Source directory [${src_dir}/precompiled-offensive-bins] does not exist. Skipping."
    fi

    # Move orpheus tool
    if [[ -d "${src_dir}/orpheus" ]]; then
        if mv "${src_dir}/orpheus" "${TOOLS_DIR}/"; then
            pass "Moved orpheus to ${TOOLS_DIR}/"
        else
            fail "Failed to move orpheus to ${TOOLS_DIR}/"
        fi
    else
        fail "Source directory [${src_dir}/orpheus] does not exist. Skipping."
    fi
fi
