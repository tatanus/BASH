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

    # TODO add stuff here
fi
