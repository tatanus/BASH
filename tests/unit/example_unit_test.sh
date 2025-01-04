#!/usr/bin/env bash
set -euo pipefail

# Source the script containing the function
#source ./lib/example_lib.sh

# Test the function
function test_example_function() {
    #    local result
    #    result=$(example_function "test_input")
    #    if [[ "$result" == "expected_output" ]]; then
    #        echo "Unit test passed."
    #        return 0
    #    else
    #        echo "Unit test failed: expected 'expected_output' but got '$result'"
    #        return 1
    #    fi
    return 0
}

test_example_function
