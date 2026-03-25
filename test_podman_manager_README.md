# Podman Manager Test Suite

This test suite provides comprehensive testing for the `podman_manager.sh` script, covering both unit and integration tests for all functionalities, including notification and alert features.

## Test Files

- `test_podman_manager.sh`: Basic test suite covering core functionality
- `comprehensive_test_podman_manager.sh`: In-depth test suite with extensive coverage
- `run_tests.sh`: Test runner script for executing the test suites

## Features Tested

### Core Functionality
- Container listing (`list`)
- Container status checking (`status`)
- Starting/stopping/restarting containers (`start`, `stop`, `restart`)
- Viewing container logs (`logs`)
- Resource statistics (`stats`, `resources`)
- Health checking (`health-check`)
- Container creation (`create`)
- Executing commands in containers (`exec`)
- Removing containers (`remove`)
- Inspecting containers (`inspect`)
- Pruning resources (`prune`)

### Advanced Features
- Configuration loading and parsing
- Logging mechanism
- Notification system (desktop notifications and emails)
- Resource usage monitoring with threshold alerts
- Health monitoring with failure detection
- Continuous monitoring with alerts

## Usage

### Running Tests

To run the comprehensive test suite:

```bash
./run_tests.sh comprehensive
```

To run the basic test suite:

```bash
./run_tests.sh basic
```

To run both test suites:

```bash
./run_tests.sh both
```

Or execute the test suites directly:

```bash
# Run basic tests
./test_podman_manager.sh

# Run comprehensive tests
./comprehensive_test_podman_manager.sh
```

## Test Structure

The comprehensive test suite follows this structure:

1. **Test Framework Setup**: Initializes counters, colors, and helper functions
2. **Unit Tests**: Individual function testing with mocking
3. **Integration Tests**: Full script execution testing
4. **Notification Tests**: Specific testing of alert mechanisms
5. **Error Handling Tests**: Validation of error conditions

## Mocking Strategy

Tests use mock implementations of the `podman` command to simulate:
- Various container states (running, stopped, exited)
- Different resource usage levels
- Health statuses (healthy, unhealthy)
- Command outputs

This allows testing all functionality without requiring actual Podman containers.

## Coverage

The test suite covers:
- All primary commands and options
- Edge cases and error conditions
- Notification and alert mechanisms
- Configuration loading
- Logging functionality
- Resource threshold monitoring
- Health monitoring systems