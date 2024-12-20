#!/usr/bin/env bash

# =============================================================================
# NAME        : spoonmap.sh
# DESCRIPTION : 
# AUTHOR      : Adam Compton
# DATE CREATED: 2024-12-09 13:49:51
# =============================================================================
# EDIT HISTORY:
# DATE                 | EDITED BY    | DESCRIPTION OF CHANGE
# ---------------------|--------------|----------------------------------------
# 2024-12-09 13:49:51  | Adam Compton | Initial creation.
# =============================================================================

function install_spoonmap() {
    _Git_Clone https://github.com/trustedsec/spoonmap.git

    _Add_Alias "function spoonmap { (cd $TOOL_DIR/spoonmap && $PYTHON $TOOL_DIR/spoonmap/spoonmap.py \"\$@\") }"
}

# Test function for spoonmap
function test_spoonmap() {
    local TOOL_NAME="spoonmap"
    local TOOL_COMMAND="ls $TOOL_DIR/spoonmap/spoonmap.py"
    AppTest "$TOOL_NAME" "$TOOL_COMMAND"
    local status=$?

    # Return the status from AppTest
    return $status
}
