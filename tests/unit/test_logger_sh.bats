#!/usr/bin/env bats

# =============================================================================
# NAME        : test_logger_sh.bats
# DESCRIPTION : BATS unit tests for verifying the logger.sh script.
# DEPENDENCIES: logger.sh must be sourced before running these tests.
# =============================================================================

# =============================================================================
# Setup: Load the logger.sh script and configure the test environment
# -----------------------------------------------------------------------------
# 1. Sources logger.sh to make its functions available for testing.
# 2. Creates a temporary directory and log file for testing purposes.
# =============================================================================
setup() {
    BASE_DIR="$(pwd)"
    export BASE_DIR

    # Source logger.sh
    if [[ -f "${BASE_DIR}/lib/logger.sh" ]]; then
        source "${BASE_DIR}/lib/logger.sh"
    else
        echo "logger.sh not found." >&2
        exit 1
    fi

    # Set up test log directory and file
    TEST_LOG_DIR=$(mktemp -d)
    TEST_LOG_FILE="${TEST_LOG_DIR}/test_logger.log"
}

# =============================================================================
# Teardown: Clean up the test environment
# -----------------------------------------------------------------------------
# Removes the temporary log directory and files created during testing.
# =============================================================================
teardown() {
    rm -rf "${TEST_LOG_DIR}"
}

# =============================================================================
# Test: Verify LOGGER_SH_LOADED guard is set
# -----------------------------------------------------------------------------
# Ensures the LOGGER_SH_LOADED guard variable is set to "true" after sourcing
# logger.sh.
# =============================================================================
@test "Verify LOGGER_SH_LOADED guard is set" {
    [ "${LOGGER_SH_LOADED:-}" == "true" ]
}

# =============================================================================
# Test: Verify log_level_priorities is declared and non-empty
# -----------------------------------------------------------------------------
# Confirms that the log_level_priorities associative array is declared and
# contains all expected log levels.
# =============================================================================
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

# =============================================================================
# Test: Logger_Init creates a logger instance with default parameters
# -----------------------------------------------------------------------------
# Verifies that Logger_Init creates a logger instance with default parameters
# and initializes all properties to expected default values.
# =============================================================================
@test "Logger_Init creates a logger instance with default parameters" {
    Logger_Init "test_logger" || {
        echo "Logger_Init failed." >&2
        return 1
    }

    [[ "${test_logger_props[log_file]}" == "${HOME}/test_logger.log" ]]
    [[ "${test_logger_props[log_level]}" == "info" ]]
    [[ "${test_logger_props[log_to_screen]}" == "true" ]]
    [[ "${test_logger_props[log_to_file]}" == "true" ]]
}

# =============================================================================
# Test: Logger_Init creates a logger instance with custom parameters
# -----------------------------------------------------------------------------
# Confirms that Logger_Init correctly initializes a logger instance with custom
# parameters provided by the user.
# =============================================================================
@test "Logger_Init creates a logger instance with custom parameters" {
    Logger_Init "custom_logger" "${TEST_LOG_FILE}" "debug" "false" "true" || {
        echo "Logger_Init failed." >&2
        return 1
    }

    [[ "${custom_logger_props[log_file]}" == "${TEST_LOG_FILE}" ]]
    [[ "${custom_logger_props[log_level]}" == "debug" ]]
    [[ "${custom_logger_props[log_to_screen]}" == "false" ]]
    [[ "${custom_logger_props[log_to_file]}" == "true" ]]
}

# =============================================================================
# Test: Logger_log writes messages to the log file
# -----------------------------------------------------------------------------
# Verifies that Logger_log writes messages to the specified log file when
# configured to log to a file.
# =============================================================================
@test "Logger_log writes messages to the log file" {
    Logger_Init "file_logger" "${TEST_LOG_FILE}" "info" "false" "true"
    file_logger.info "Test message for file logging"
    [ -f "${TEST_LOG_FILE}" ]
    run grep "Test message for file logging" "${TEST_LOG_FILE}"
    [ "$status" -eq 0 ]
}

# =============================================================================
# Test: Logger_log displays messages on the screen
# -----------------------------------------------------------------------------
# Confirms that Logger_log displays messages on the screen when configured to
# log to the screen.
# =============================================================================
@test "Logger_log displays messages on the screen" {
    Logger_Init "screen_logger" "/dev/null" "info" "true" "false"
    run screen_logger.info "Test message for screen logging"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Test message for screen logging"* ]]
}

# =============================================================================
# Test: Logger respects log level hierarchy
# -----------------------------------------------------------------------------
# Ensures that Logger only logs messages equal to or above the configured log
# level, ignoring messages below the threshold.
# =============================================================================
@test "Logger only logs messages equal to or above the configured log level" {
    Logger_Init "level_logger" "${TEST_LOG_FILE}" "warn" "false" "true"
    level_logger.info "This should not be logged"
    level_logger.warn "This should be logged"

    run grep "This should not be logged" "${TEST_LOG_FILE}"
    [ "$status" -ne 0 ]

    run grep "This should be logged" "${TEST_LOG_FILE}"
    [ "$status" -eq 0 ]
}

# =============================================================================
# Test: Logger_log fails with an invalid log level
# -----------------------------------------------------------------------------
# Validates that Logger_log returns an error when an invalid log level is used.
# =============================================================================
@test "Logger_log fails with an invalid log level" {
    Logger_Init "invalid_logger" "${TEST_LOG_FILE}" "info" "true" "true"
    run Logger_log "invalid_logger" "invalid_level" "This message should fail"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Error: Invalid log level 'invalid_level'"* ]]
}

# =============================================================================
# Test: Logger_log fails when using a non-existent logger instance
# -----------------------------------------------------------------------------
# Ensures that Logger_log returns an error when attempting to log using a
# non-existent logger instance.
# =============================================================================
@test "Logger_log fails when using a non-existent logger instance" {
    run Logger_log "non_existent_logger" "info" "Message"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Logger instance 'non_existent_logger' does not exist"* ]]
}

# =============================================================================
# Test: Logger_Init fails with an invalid instance name
# -----------------------------------------------------------------------------
# Confirms that Logger_Init returns an error when attempting to initialize a
# logger with an invalid instance name.
# =============================================================================
@test "Logger_Init fails with an invalid instance name" {
    run Logger_Init "123invalid"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Invalid instance name"* ]]
}

# =============================================================================
# Test: Set and get logger properties dynamically
# -----------------------------------------------------------------------------
# Verifies that logger properties can be set and retrieved dynamically at
# runtime using the set_log_level and get_log_level methods.
# =============================================================================
@test "Set and get logger properties dynamically" {
    Logger_Init "dynamic_logger" "${TEST_LOG_FILE}" "info" "true" "true"
    dynamic_logger.set_log_level "debug"
    run dynamic_logger.get_log_level
    [ "$status" -eq 0 ]
    [[ "$output" == "debug" ]]
}

# =============================================================================
# Test: Debug log includes caller information
# -----------------------------------------------------------------------------
# Ensures that debug logs include caller information when the log level is set
# to debug.
# =============================================================================
@test "Debug log includes caller information" {
    Logger_Init "debug_logger" "${TEST_LOG_FILE}" "debug" "true" "true"
    run debug_logger.debug "Debug message"
    [ "$status" -eq 0 ]
    [[ "$output" == *"CALLER:"* ]]
}