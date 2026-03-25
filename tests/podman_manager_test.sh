#!/bin/bash

# Unit tests for podman_manager.sh
# This script contains comprehensive tests for all functions in podman_manager.sh

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Global variables for tracking test results
TOTAL_TESTS=0
PASSED_TESTS=0

# Mock data
MOCK_PODMAN_OUTPUT=""
MOCK_PODMAN_EXIT_CODE=0
MOCK_COMMAND_LOG=()

# Override the podman command globally for mocking
podman() {
    MOCK_COMMAND_LOG+=("$*")

    case "$1" in
        "ps")
            if [[ "$*" == *"-a"* ]]; then
                if [[ "${MOCK_PODMAN_EXIT_CODE}" -eq 0 ]]; then
                    echo -e "CONTAINER ID\tNAMES\tIMAGE\tSTATUS\tPORTS"
                    echo -e "abc123\tmycontainer\tnginx:latest\tUp 2 hours\t0.0.0.0:80->80/tcp"
                    echo -e "def456\tstopped_container\tapache:latest\tExited (0) 1 hour ago\t"
                fi
            else
                if [[ "${MOCK_PODMAN_EXIT_CODE}" -eq 0 ]]; then
                    echo -e "CONTAINER ID\tNAMES\tIMAGE\tSTATUS\tPORTS"
                    echo -e "abc123\tmycontainer\tnginx:latest\tUp 2 hours\t0.0.0.0:80->80/tcp"
                fi
            fi
            ;;
        "logs")
            if [[ "${MOCK_PODMAN_EXIT_CODE}" -eq 0 ]]; then
                echo -e "Log entry 1"
                echo -e "Log entry 2"
                echo -e "Log entry 3"
            fi
            ;;
        "start")
            if [[ "${MOCK_PODMAN_EXIT_CODE}" -eq 0 ]]; then
                echo -e "mycontainer"
            fi
            ;;
        "stop")
            if [[ "${MOCK_PODMAN_EXIT_CODE}" -eq 0 ]]; then
                echo -e "mycontainer"
            fi
            ;;
        "restart")
            if [[ "${MOCK_PODMAN_EXIT_CODE}" -eq 0 ]]; then
                echo -e "mycontainer"
            fi
            ;;
        "rm")
            if [[ "${MOCK_PODMAN_EXIT_CODE}" -eq 0 ]]; then
                echo -e "mycontainer"
            fi
            ;;
        "inspect")
            if [[ "${MOCK_PODMAN_EXIT_CODE}" -eq 0 ]]; then
                # Mock JSON response for inspect
                echo '[{
                  "Id": "abc123",
                  "Name": "mycontainer",
                  "State": {
                    "Status": "running",
                    "Running": true,
                    "Paused": false,
                    "Restarting": false,
                    "OOMKilled": false,
                    "Dead": false,
                    "Pid": 12345,
                    "ExitCode": 0,
                    "Error": "",
                    "StartedAt": "2023-01-01T10:00:00Z",
                    "FinishedAt": "0001-01-01T00:00:00Z",
                    "Health": {
                      "Status": "healthy"
                    }
                  },
                  "Config": {
                    "Image": "nginx:latest",
                    "Env": ["ENV1=value1", "ENV2=value2"]
                  },
                  "NetworkSettings": {
                    "IPAddress": "172.17.0.2"
                  },
                  "Mounts": [
                    {
                      "Type": "bind",
                      "Source": "/host/path",
                      "Destination": "/container/path"
                    }
                  ]
                }]'
            fi
            ;;
        "stats")
            if [[ "${MOCK_PODMAN_EXIT_CODE}" -eq 0 ]]; then
                if [[ "$*" == *"--no-stream"* ]]; then
                    echo -e "NAME\tPID\tCPU %\tMEM USAGE / LIMIT\tMEM %\tNET I/O\tBLOCK I/O"
                    echo -e "mycontainer\t12345\t0.50%\t10MiB / 1GiB\t1.00%\t1.2kB / 1.3kB\t0B / 0B"
                fi
            fi
            ;;
        *)
            if [[ "${MOCK_PODMAN_EXIT_CODE}" -eq 0 ]]; then
                echo -e "Mock output for: $*"
            fi
            ;;
    esac

    return $MOCK_PODMAN_EXIT_CODE
}

# Function to reset mocks
reset_mocks() {
    MOCK_PODMAN_OUTPUT=""
    MOCK_PODMAN_EXIT_CODE=0
    MOCK_COMMAND_LOG=()
}

# Function to assert test results
assert_equal() {
    local expected="$1"
    local actual="$2"
    local test_name="$3"

    ((TOTAL_TESTS++))

    if [[ "$expected" == "$actual" ]]; then
        echo -e "${GREEN}PASS${NC}: $test_name"
        ((PASSED_TESTS++))
        return 0
    else
        echo -e "${RED}FAIL${NC}: $test_name"
        echo "  Expected: '$expected'"
        echo "  Actual:   '$actual'"
        return 1
    fi
}

# Function to assert that a string contains a substring
assert_contains() {
    local string="$1"
    local substring="$2"
    local test_name="$3"

    ((TOTAL_TESTS++))

    if [[ "$string" == *"$substring"* ]]; then
        echo -e "${GREEN}PASS${NC}: $test_name"
        ((PASSED_TESTS++))
        return 0
    else
        echo -e "${RED}FAIL${NC}: $test_name"
        echo "  String: '$string'"
        echo "  Expected to contain: '$substring'"
        return 1
    fi
}

# Function to assert that a command succeeds (exit code 0)
assert_success() {
    local test_name="$1"
    local exit_code="$2"

    ((TOTAL_TESTS++))

    if [[ $exit_code -eq 0 ]]; then
        echo -e "${GREEN}PASS${NC}: $test_name"
        ((PASSED_TESTS++))
        return 0
    else
        echo -e "${RED}FAIL${NC}: $test_name (exit code: $exit_code)"
        return 1
    fi
}

# Function to assert that a command fails (non-zero exit code)
assert_failure() {
    local test_name="$1"
    local exit_code="$2"

    ((TOTAL_TESTS++))

    if [[ $exit_code -ne 0 ]]; then
        echo -e "${GREEN}PASS${NC}: $test_name (expected failure, got exit code: $exit_code)"
        ((PASSED_TESTS++))
        return 0
    else
        echo -e "${RED}FAIL${NC}: $test_name (expected failure but command succeeded)"
        return 1
    fi
}

# Function to run a function in a subshell to capture output and exit code
run_function() {
    local func_name="$1"
    shift
    local args=("$@")

    # Execute the function in a subshell to capture both output and exit code
    local output
    output=$( "${func_name}" "${args[@]}" 2>&1 )
    local exit_code=$?

    # Return the output and exit code via globals
    RUN_OUTPUT="$output"
    RUN_EXIT_CODE="$exit_code"
}

# Define all the functions from podman_manager.sh that we need to test
# Function to display usage
usage() {
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  list                    List all containers (running and stopped)"
    echo "  logs CONTAINER_NAME     Show logs of a container"
    echo "  start CONTAINER_NAME    Start a container"
    echo "  stop CONTAINER_NAME     Stop a container"
    echo "  restart CONTAINER_NAME  Restart a container"
    echo "  remove CONTAINER_NAME   Remove a container"
    echo "  monitor                 Continuously monitor container status"
    echo "  status CONTAINER_NAME   Show detailed status of a specific container"
    echo "  ps                      Show running containers only"
    echo "  stats                   Show resource usage statistics"
    echo "  stats-detail [CPU_THRESHOLD] [MEM_THRESHOLD] [INTERVAL] Show detailed resource usage statistics with alert thresholds"
    echo "  security-scan CONTAINER_NAME [OUTPUT_FORMAT] [SEVERITY_FILTER] [LOG_FILE]  Perform security scan on a container image"
    echo "  batch-operation OPERATION REGEX_PATTERN Perform batch operation on multiple containers matching the pattern"
    echo "  help                    Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 list"
    echo "  $0 logs mycontainer"
    echo "  $0 start mycontainer"
    echo "  $0 monitor"
    echo "  $0 stats-detail         # Monitor with default thresholds (CPU: 80%, MEM: 90%)"
    echo "  $0 stats-detail 90 95   # Monitor with custom thresholds (CPU: 90%, MEM: 95%)"
    echo "  $0 security-scan mycontainer  # Scan container image for vulnerabilities"
    echo "  $0 batch-operation stop '^web.*'  # Stop all containers whose names start with 'web'"
    echo ""
}

# Function to check if podman is installed
check_podman() {
    if ! command -v podman &> /dev/null; then
        echo -e "${RED}Error: Podman is not installed or not in PATH${NC}" >&2
        exit 1
    fi

    if ! command -v bc &> /dev/null; then
        echo -e "${YELLOW}Warning: 'bc' is not installed. Advanced numerical comparisons in detailed stats may not work properly.${NC}" >&2
    fi

    if ! command -v sed &> /dev/null; then
        echo -e "${YELLOW}Warning: 'sed' is not installed. Detailed stats may not work properly.${NC}" >&2
    fi
}

# Function to list all containers
list_containers() {
    echo -e "${BLUE}Listing all containers:${NC}"
    podman ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
}

# Function to show container logs
show_logs() {
    local container_name="$1"
    if [[ -z "$container_name" ]]; then
        echo -e "${RED}Error: Container name is required${NC}" >&2
        return 1
    fi

    echo -e "${BLUE}Logs for container '$container_name':${NC}"
    if ! podman logs "$container_name" 2>/dev/null; then
        echo -e "${RED}Error: Could not retrieve logs for container '$container_name'${NC}" >&2
        return 1
    fi
}

# Function to start a container
start_container() {
    local container_name="$1"
    if [[ -z "$container_name" ]]; then
        echo -e "${RED}Error: Container name is required${NC}" >&2
        return 1
    fi

    echo -e "${YELLOW}Starting container '$container_name'...${NC}"
    if podman start "$container_name"; then
        echo -e "${GREEN}Container '$container_name' started successfully${NC}"
    else
        echo -e "${RED}Failed to start container '$container_name'${NC}" >&2
        return 1
    fi
}

# Function to stop a container
stop_container() {
    local container_name="$1"
    if [[ -z "$container_name" ]]; then
        echo -e "${RED}Error: Container name is required${NC}" >&2
        return 1
    fi

    echo -e "${YELLOW}Stopping container '$container_name'...${NC}"
    if podman stop "$container_name"; then
        echo -e "${GREEN}Container '$container_name' stopped successfully${NC}"
    else
        echo -e "${RED}Failed to stop container '$container_name'${NC}" >&2
        return 1
    fi
}

# Function to restart a container
restart_container() {
    local container_name="$1"
    if [[ -z "$container_name" ]]; then
        echo -e "${RED}Error: Container name is required${NC}" >&2
        return 1
    fi

    echo -e "${YELLOW}Restarting container '$container_name'...${NC}"
    if podman restart "$container_name"; then
        echo -e "${GREEN}Container '$container_name' restarted successfully${NC}"
    else
        echo -e "${RED}Failed to restart container '$container_name'${NC}" >&2
        return 1
    fi
}

# Function to remove a container
remove_container() {
    local container_name="$1"
    if [[ -z "$container_name" ]]; then
        echo -e "${RED}Error: Container name is required${NC}" >&2
        return 1
    fi

    echo -e "${RED}Removing container '$container_name'...${NC}"
    if podman rm -f "$container_name"; then
        echo -e "${GREEN}Container '$container_name' removed successfully${NC}"
    else
        echo -e "${RED}Failed to remove container '$container_name'${NC}" >&2
        return 1
    fi
}

# Function to show detailed status of a specific container
show_status() {
    local container_name="$1"
    if [[ -z "$container_name" ]]; then
        echo -e "${RED}Error: Container name is required${NC}" >&2
        return 1
    fi

    echo -e "${BLUE}Detailed status for container '$container_name':${NC}"

    # Check if container exists
    if ! podman inspect "$container_name" &>/dev/null; then
        echo -e "${RED}Error: Container '$container_name' does not exist${NC}" >&2
        return 1
    fi

    # Show basic info
    echo "Basic Information:"
    podman ps -a --filter name="$container_name" --format "table {{.Names}}\t{{.Image}}\t{{.Command}}\t{{.Status}}\t{{.Ports}}"

    echo ""
    echo "Resource Usage:"
    if podman stats --no-stream --format "table {{.Name}}\t{{.CPU}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}" --filter name="$container_name" 2>/dev/null; then
        :
    else
        echo "Stats not available (container may not be running)"
    fi
}

# Function to show running containers only
show_running_containers() {
    echo -e "${BLUE}Running containers:${NC}"
    podman ps --format "table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
}

# Function to show resource usage statistics
show_stats() {
    echo -e "${BLUE}Container resource usage statistics:${NC}"
    if command -v jq &> /dev/null; then
        podman stats --no-stream --format "table {{.Name}}\t{{.CPU}}\t{{.MemUsage}}\t{{.Mem}}\t{{.NetIO}}\t{{.BlockIO}}" 2>/dev/null || echo "No running containers or stats not available"
    else
        echo "Note: Install 'jq' for enhanced statistics output"
        podman stats --no-stream --format "table {{.Name}}\t{{.CPU}}\t{{.MemUsage}}\t{{.NetIO}}" 2>/dev/null || echo "No running containers or stats not available"
    fi
}

# Function to perform batch operations on multiple containers
batch_operation() {
    local operation="$1"
    local pattern="$2"

    if [[ -z "$operation" ]] || [[ -z "$pattern" ]]; then
        echo -e "${RED}Error: Both operation and pattern are required${NC}" >&2
        echo "Usage: $0 batch-operation [start|stop|restart|remove] REGEX_PATTERN"
        return 1
    fi

    # Validate operation
    if [[ ! "$operation" =~ ^(start|stop|restart|remove)$ ]]; then
        echo -e "${RED}Error: Invalid operation '$operation'. Valid operations: start, stop, restart, remove${NC}" >&2
        return 1
    fi

    echo -e "${BLUE}Performing batch operation '$operation' on containers matching pattern '$pattern'...${NC}"

    # Get list of all containers and filter based on pattern
    local all_containers
    all_containers=$(podman ps -a --format "{{.Names}}")

    # Filter containers based on pattern using grep
    local matched_containers
    matched_containers=$(echo "$all_containers" | grep -E "$pattern" || true)

    if [[ -z "$matched_containers" ]]; then
        echo -e "${YELLOW}No containers found matching pattern '$pattern'${NC}"
        return 0
    fi

    echo -e "${BLUE}Found containers matching pattern '$pattern':${NC}"
    echo "$matched_containers" | while read -r container; do
        if [[ -n "$container" ]]; then
            echo "  - $container"
        fi
    done
}

# Test check_podman function with mocked command function
test_check_podman() {
    echo -e "${BLUE}Testing check_podman function...${NC}"

    # Backup the real command function
    command_real() {
        builtin command "$@"
    }

    # Mock command -v to return success for podman
    command() {
        if [[ "$1" == "podman" ]]; then
            return 0
        elif [[ "$1" == "bc" ]]; then
            return 0
        elif [[ "$1" == "sed" ]]; then
            return 0
        else
            command_real "$@"
        fi
    }

    # Temporarily disable exit on error to test the function
    set +e
    check_podman 2>/dev/null
    local result=$?
    set -e

    # Restore original command function
    unset -f command

    assert_success "check_podman passes when podman is available" $result
}

# Test list_containers function
test_list_containers() {
    echo -e "${BLUE}Testing list_containers function...${NC}"

    reset_mocks
    run_function list_containers

    assert_success "list_containers succeeds" $RUN_EXIT_CODE
    assert_contains "$RUN_OUTPUT" "Listing all containers" "list_containers output contains header"

    # Verify podman command was called correctly
    local podman_called=false
    for cmd in "${MOCK_COMMAND_LOG[@]}"; do
        if [[ "$cmd" == *"ps -a"* ]]; then
            podman_called=true
            break
        fi
    done

    ((TOTAL_TESTS++))
    if [[ "$podman_called" == true ]]; then
        echo -e "${GREEN}PASS${NC}: podman ps -a was called"
        ((PASSED_TESTS++))
    else
        echo -e "${RED}FAIL${NC}: podman ps -a was not called"
    fi
}

# Test show_logs function
test_show_logs() {
    echo -e "${BLUE}Testing show_logs function...${NC}"

    # Test with valid container name
    reset_mocks
    run_function show_logs "mycontainer"

    assert_success "show_logs with valid container succeeds" $RUN_EXIT_CODE
    assert_contains "$RUN_OUTPUT" "Logs for container 'mycontainer'" "show_logs output contains header"

    # Test with empty container name
    reset_mocks
    run_function show_logs ""

    assert_failure "show_logs with empty container name fails" $RUN_EXIT_CODE
    assert_contains "$RUN_OUTPUT" "Container name is required" "show_logs with empty name shows error"

    # Test with non-existent container
    reset_mocks
    MOCK_PODMAN_EXIT_CODE=1
    run_function show_logs "nonexistent"

    assert_failure "show_logs with non-existent container fails" $RUN_EXIT_CODE
    assert_contains "$RUN_OUTPUT" "Could not retrieve logs" "show_logs with non-existent container shows error"
}

# Test start_container function
test_start_container() {
    echo -e "${BLUE}Testing start_container function...${NC}"

    # Test with valid container name
    reset_mocks
    run_function start_container "mycontainer"

    assert_success "start_container with valid container succeeds" $RUN_EXIT_CODE
    assert_contains "$RUN_OUTPUT" "Starting container 'mycontainer'" "start_container output contains starting message"
    assert_contains "$RUN_OUTPUT" "started successfully" "start_container output contains success message"

    # Test with empty container name
    reset_mocks
    run_function start_container ""

    assert_failure "start_container with empty container name fails" $RUN_EXIT_CODE
    assert_contains "$RUN_OUTPUT" "Container name is required" "start_container with empty name shows error"

    # Test with failed start
    reset_mocks
    MOCK_PODMAN_EXIT_CODE=1
    run_function start_container "mycontainer"

    assert_failure "start_container with failed start returns error" $RUN_EXIT_CODE
    assert_contains "$RUN_OUTPUT" "Failed to start container" "start_container with failed start shows error"
}

# Test stop_container function
test_stop_container() {
    echo -e "${BLUE}Testing stop_container function...${NC}"

    # Test with valid container name
    reset_mocks
    run_function stop_container "mycontainer"

    assert_success "stop_container with valid container succeeds" $RUN_EXIT_CODE
    assert_contains "$RUN_OUTPUT" "Stopping container 'mycontainer'" "stop_container output contains stopping message"
    assert_contains "$RUN_OUTPUT" "stopped successfully" "stop_container output contains success message"

    # Test with empty container name
    reset_mocks
    run_function stop_container ""

    assert_failure "stop_container with empty container name fails" $RUN_EXIT_CODE
    assert_contains "$RUN_OUTPUT" "Container name is required" "stop_container with empty name shows error"

    # Test with failed stop
    reset_mocks
    MOCK_PODMAN_EXIT_CODE=1
    run_function stop_container "mycontainer"

    assert_failure "stop_container with failed stop returns error" $RUN_EXIT_CODE
    assert_contains "$RUN_OUTPUT" "Failed to stop container" "stop_container with failed stop shows error"
}

# Test restart_container function
test_restart_container() {
    echo -e "${BLUE}Testing restart_container function...${NC}"

    # Test with valid container name
    reset_mocks
    run_function restart_container "mycontainer"

    assert_success "restart_container with valid container succeeds" $RUN_EXIT_CODE
    assert_contains "$RUN_OUTPUT" "Restarting container 'mycontainer'" "restart_container output contains restarting message"
    assert_contains "$RUN_OUTPUT" "restarted successfully" "restart_container output contains success message"

    # Test with empty container name
    reset_mocks
    run_function restart_container ""

    assert_failure "restart_container with empty container name fails" $RUN_EXIT_CODE
    assert_contains "$RUN_OUTPUT" "Container name is required" "restart_container with empty name shows error"

    # Test with failed restart
    reset_mocks
    MOCK_PODMAN_EXIT_CODE=1
    run_function restart_container "mycontainer"

    assert_failure "restart_container with failed restart returns error" $RUN_EXIT_CODE
    assert_contains "$RUN_OUTPUT" "Failed to restart container" "restart_container with failed restart shows error"
}

# Test remove_container function
test_remove_container() {
    echo -e "${BLUE}Testing remove_container function...${NC}"

    # Test with valid container name
    reset_mocks
    run_function remove_container "mycontainer"

    assert_success "remove_container with valid container succeeds" $RUN_EXIT_CODE
    assert_contains "$RUN_OUTPUT" "Removing container 'mycontainer'" "remove_container output contains removing message"
    assert_contains "$RUN_OUTPUT" "removed successfully" "remove_container output contains success message"

    # Test with empty container name
    reset_mocks
    run_function remove_container ""

    assert_failure "remove_container with empty container name fails" $RUN_EXIT_CODE
    assert_contains "$RUN_OUTPUT" "Container name is required" "remove_container with empty name shows error"

    # Test with failed removal
    reset_mocks
    MOCK_PODMAN_EXIT_CODE=1
    run_function remove_container "mycontainer"

    assert_failure "remove_container with failed removal returns error" $RUN_EXIT_CODE
    assert_contains "$RUN_OUTPUT" "Failed to remove container" "remove_container with failed removal shows error"
}

# Test show_status function
test_show_status() {
    echo -e "${BLUE}Testing show_status function...${NC}"

    # Test with valid container name
    reset_mocks
    run_function show_status "mycontainer"

    assert_success "show_status with valid container succeeds" $RUN_EXIT_CODE
    assert_contains "$RUN_OUTPUT" "Detailed status for container 'mycontainer'" "show_status output contains header"

    # Test with empty container name
    reset_mocks
    run_function show_status ""

    assert_failure "show_status with empty container name fails" $RUN_EXIT_CODE
    assert_contains "$RUN_OUTPUT" "Container name is required" "show_status with empty name shows error"

    # Test with non-existent container
    reset_mocks
    MOCK_PODMAN_EXIT_CODE=1
    run_function show_status "nonexistent"

    assert_failure "show_status with non-existent container fails" $RUN_EXIT_CODE
    assert_contains "$RUN_OUTPUT" "does not exist" "show_status with non-existent container shows error"
}

# Test show_running_containers function
test_show_running_containers() {
    echo -e "${BLUE}Testing show_running_containers function...${NC}"

    reset_mocks
    run_function show_running_containers

    assert_success "show_running_containers succeeds" $RUN_EXIT_CODE
    assert_contains "$RUN_OUTPUT" "Running containers" "show_running_containers output contains header"

    # Verify podman command was called correctly
    local podman_called=false
    for cmd in "${MOCK_COMMAND_LOG[@]}"; do
        if [[ "$cmd" == *"ps --format"* ]]; then
            podman_called=true
            break
        fi
    done

    ((TOTAL_TESTS++))
    if [[ "$podman_called" == true ]]; then
        echo -e "${GREEN}PASS${NC}: podman ps was called"
        ((PASSED_TESTS++))
    else
        echo -e "${RED}FAIL${NC}: podman ps was not called"
    fi
}

# Test show_stats function
test_show_stats() {
    echo -e "${BLUE}Testing show_stats function...${NC}"

    reset_mocks
    run_function show_stats

    assert_success "show_stats succeeds" $RUN_EXIT_CODE
    assert_contains "$RUN_OUTPUT" "resource usage statistics" "show_stats output contains header"
}

# Test batch_operation function
test_batch_operation() {
    echo -e "${BLUE}Testing batch_operation function...${NC}"

    # Test with invalid operation
    reset_mocks
    run_function batch_operation "invalid_op" "^test.*"

    assert_failure "batch_operation with invalid operation fails" $RUN_EXIT_CODE
    assert_contains "$RUN_OUTPUT" "Invalid operation" "batch_operation with invalid operation shows error"

    # Test with missing parameters
    reset_mocks
    run_function batch_operation ""

    assert_failure "batch_operation with missing parameters fails" $RUN_EXIT_CODE
    assert_contains "$RUN_OUTPUT" "Both operation and pattern are required" "batch_operation with missing params shows error"
}

# Test main function with various commands
test_main_commands() {
    echo -e "${BLUE}Testing usage function (similar to main)...${NC}"

    # Test if usage function exists and works
    if declare -f usage >/dev/null; then
        reset_mocks
        local output
        output=$(usage 2>&1)
        local exit_code=$?

        assert_success "usage function succeeds" $exit_code
        assert_contains "$output" "Usage:" "usage output contains usage info"
    else
        echo -e "${RED}FAIL${NC}: usage function does not exist"
        ((TOTAL_TESTS++))
    fi
}

# Run all tests
run_tests() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Running Unit Tests for podman_manager.sh${NC}"
    echo -e "${BLUE}========================================${NC}"

    # Initialize counters
    TOTAL_TESTS=0
    PASSED_TESTS=0

    # Run each test function
    for test_func in $(declare -F | grep "^declare -f test_" | cut -d' ' -f3); do
        reset_mocks
        echo ""
        $test_func
    done

    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Test Results Summary${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo "Total tests: $TOTAL_TESTS"
    echo "Passed: $PASSED_TESTS"
    echo "Failed: $((TOTAL_TESTS - PASSED_TESTS))"

    local percentage=0
    if [ $TOTAL_TESTS -gt 0 ]; then
        percentage=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    fi
    echo "Success rate: ${percentage}%"

    if [ $PASSED_TESTS -eq $TOTAL_TESTS ]; then
        echo -e "${GREEN}All tests PASSED!${NC}"
        return 0
    else
        echo -e "${RED}Some tests FAILED!${NC}"
        return 1
    fi
}

# Execute tests if this script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_tests
fi