#!/usr/bin/env bats

# =============================================================================
# NAME        : test_logger_sh.bats
# DESCRIPTION : BATS unit tests for verifying the logger.sh script.
# DEPENDENCIES: logger.sh must be sourced before running these tests.
# =============================================================================

# Setup: Load the logger.sh script
setup() {
    SCRIPT_DIR="$(pwd)"
    export SCRIPT_DIR

    if [[ -f "${SCRIPT_DIR}/lib/logger.sh" ]]; then
        source "${SCRIPT_DIR}/lib/logger.sh"
    else
        echo "logger.sh not found." >&2
        exit 1
    fi

    TEST_LOG_DIR=$(mktemp -d)
    TEST_LOG_FILE="${TEST_LOG_DIR}/test_logger.log"
}

# Teardown: Clean up the temporary directory
teardown() {
    rm -rf "${TEST_LOG_DIR}"
}

# Test: Ensure the LOGGER_SH_LOADED guard is set
@test "Verify LOGGER_SH_LOADED guard is set" {
    [ "${LOGGER_SH_LOADED}" == "true" ]
}

# Test: Verify log_level_priorities is declared and non-empty
@test "Verify log_level_priorities is declared and non-empty" {
    declare_output=$(declare -p log_level_priorities 2>/dev/null || true)
    [[ "${declare_output}" =~ "declare -A" ]] || {
        echo "log_level_priorities is not declared as an associative array"
        return 1
    }

    [ "${#log_level_priorities[@]}" -gt 0 ] || {
        echo "log_level_priorities is declared but empty"
        return 1
    }

    for level in debug info warn pass fail; do
        [[ -n "${log_level_priorities[${level}]:-}" ]] || {
            echo "Log level '${level}' is missing in log_level_priorities"
            return 1
        }
    done
}


@test "Logger_Init creates a logger instance with default parameters" {
    Logger_Init "test_logger" || {
        echo "Logger_Init failed." >&2
        return 1
    }

    # Debugging: Check if the associative array is declared
    declare_output=$(declare -p test_logger_props 2>/dev/null || true)
    echo "Declare output: ${declare_output}" >&2

    # Verify the properties directly
    [[ "${test_logger_props[log_file]}" == "${HOME}/test_logger.log" ]] || {
        echo "Expected log_file to be ${HOME}/test_logger.log, but got: ${test_logger_props[log_file]}"
        return 1
    }
    [[ "${test_logger_props[log_level]}" == "info" ]] || {
        echo "Expected log_level to be info, but got: ${test_logger_props[log_level]}"
        return 1
    }
    [[ "${test_logger_props[log_to_screen]}" == "true" ]] || {
        echo "Expected log_to_screen to be true, but got: ${test_logger_props[log_to_screen]}"
        return 1
    }
    [[ "${test_logger_props[log_to_file]}" == "true" ]] || {
        echo "Expected log_to_file to be true, but got: ${test_logger_props[log_to_file]}"
        return 1
    }
}


@test "Logger_Init creates a logger instance with custom parameters" {
    Logger_Init "custom_logger" "${TEST_LOG_FILE}" "debug" "false" "true" || {
        echo "Logger_Init failed." >&2
        return 1
    }

    # Debugging: Check if the associative array is declared
    declare_output=$(declare -p custom_logger_props 2>/dev/null || true)
    echo "Declare output: ${declare_output}" >&2

    # Verify the properties directly
    [[ "${custom_logger_props[log_file]}" == "${TEST_LOG_FILE}" ]] || {
        echo "Expected log_file to be ${TEST_LOG_FILE}, but got: ${custom_logger_props[log_file]}"
        return 1
    }
    [[ "${custom_logger_props[log_level]}" == "debug" ]] || {
        echo "Expected log_level to be debug, but got: ${custom_logger_props[log_level]}"
        return 1
    }
    [[ "${custom_logger_props[log_to_screen]}" == "false" ]] || {
        echo "Expected log_to_screen to be false, but got: ${custom_logger_props[log_to_screen]}"
        return 1
    }
    [[ "${custom_logger_props[log_to_file]}" == "true" ]] || {
        echo "Expected log_to_file to be true, but got: ${custom_logger_props[log_to_file]}"
        return 1
    }
}

# Test: Logging a message to the log file
@test "Logger_log writes messages to the log file" {
    Logger_Init "file_logger" "${TEST_LOG_FILE}" "info" "false" "true"
    file_logger.info "Test message for file logging"
    [ -f "${TEST_LOG_FILE}" ]
    run grep "Test message for file logging" "${TEST_LOG_FILE}"
    [ "$status" -eq 0 ]
}

# Test: Logging a message to the screen
@test "Logger_log displays messages on the screen" {
    Logger_Init "screen_logger" "/dev/null" "info" "true" "false"
    run screen_logger.info "Test message for screen logging"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Test message for screen logging"* ]]
}

# Test: Logger respects log level hierarchy
@test "Logger only logs messages equal to or above the configured log level" {
    Logger_Init "level_logger" "${TEST_LOG_FILE}" "warn" "false" "true"
    level_logger.info "This should not be logged"
    level_logger.warn "This should be logged"

    run cat "${TEST_LOG_FILE}"
    echo "Log file contents: ${output}" >&2

    run grep "This should not be logged" "${TEST_LOG_FILE}"
    [ "$status" -ne 0 ]

    run grep "This should be logged" "${TEST_LOG_FILE}"
    [ "$status" -eq 0 ]
}

# Test: Logger_log fails with an invalid log level
@test "Logger_log fails with an invalid log level" {
    Logger_Init "invalid_logger" "${TEST_LOG_FILE}" "info" "true" "true"
    run Logger_log "invalid_logger" "invalid_level" "This message should fail"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Error: Invalid log level 'invalid_level'"* ]]
}

# Test: Logger_log fails when using a non-existent logger instance
@test "Logger_log fails when using a non-existent logger instance" {
    run Logger_log "non_existent_logger" "info" "Message"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Logger instance 'non_existent_logger' does not exist"* ]]
}

# Test: Logger_Init fails with an invalid instance name
@test "Logger_Init fails with an invalid instance name" {
    run Logger_Init "123invalid"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Invalid instance name"* ]]
}

# Test: Dynamically set and get logger properties
@test "Set and get logger properties dynamically" {
    Logger_Init "dynamic_logger" "${TEST_LOG_FILE}" "info" "true" "true"
    dynamic_logger.set_log_level "debug"
    run dynamic_logger.get_log_level
    [ "$status" -eq 0 ]
    [[ "$output" == "debug" ]]
}

# Test: Debug log includes caller information
@test "Debug log includes caller information" {
    Logger_Init "debug_logger" "${TEST_LOG_FILE}" "debug" "true" "true"
    run debug_logger.debug "Debug message"
    [ "$status" -eq 0 ]
    [[ "$output" == *"CALLER:"* ]]
}