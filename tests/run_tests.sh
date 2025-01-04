#!/usr/bin/env bash

# Ensure the script exits on error
set -euo pipefail

# Helper function to print test results
function print_result() {
    local name="$1"
    local result="$2"
    if [[ "${result}" -eq 0 ]]; then
        echo -e "[\e[32mPASS\e[0m] ${name}"
    else
        echo -e "[\e[31mFAIL\e[0m] ${name}"
    fi
}

# Run all tests
function run_all_tests() {
    local failed=0

    echo "Running ShellCheck..."
    ./tests/shellcheck_test.sh || failed=1

    echo "Running Unit Tests..."
    for test_script in ./tests/unit/*.sh; do
        bash "${test_script}"
        print_result "$(basename "${test_script}")" $?
    done

    echo "Running Integration Tests..."
    for test_script in ./tests/integration/*.sh; do
        bash "${test_script}"
        print_result "$(basename "${test_script}")" $?
    done

    echo "Running Functional Tests..."
    for test_script in ./tests/functional/*.sh; do
        bash "${test_script}"
        print_result "$(basename "${test_script}")" $?
    done

    if [[ "${failed}" -ne 0 ]]; then
        echo "Some tests failed. Check the logs above."
        exit 1
    fi

    echo "All tests passed successfully!"
}

run_all_tests
