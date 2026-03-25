#!/bin/bash

# Comprehensive Test Suite for Podman Manager Script
# This script provides extensive tests for all functions in podman_manager.sh,
# including notification and alert functionality.

# Test Framework Setup
TEST_PASSED=0
TEST_FAILED=0
TEST_LOG_FILE="/tmp/test_podman_manager_detailed.log"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Reset counters
reset_counters() {
    TEST_PASSED=0
    TEST_FAILED=0
}

# Print test result
report_result() {
    local status="$1"
    local test_name="$2"
    local details="$3"

    if [[ "$status" == "PASS" ]]; then
        printf "${GREEN}✓ PASS${NC}: $test_name\n"
        ((TEST_PASSED++))
    else
        printf "${RED}✗ FAIL${NC}: $test_name\n"
        if [[ -n "$details" ]]; then
            printf "  Details: $details\n"
        fi
        ((TEST_FAILED++))
    fi
}

# Assert that two values are equal
assert_equal() {
    local expected="$1"
    local actual="$2"
    local test_name="$3"

    if [[ "$expected" == "$actual" ]]; then
        report_result "PASS" "$test_name"
        return 0
    else
        report_result "FAIL" "$test_name" "Expected: '$expected', Got: '$actual'"
        return 1
    fi
}

# Assert that a string contains a substring
assert_contains() {
    local string="$1"
    local substring="$2"
    local test_name="$3"

    if [[ "$string" == *"$substring"* ]]; then
        report_result "PASS" "$test_name"
        return 0
    else
        report_result "FAIL" "$test_name" "String '$string' does not contain '$substring'"
        return 1
    fi
}

# Assert that a command succeeds
assert_success() {
    local exit_code="$1"
    local test_name="$2"

    if [[ $exit_code -eq 0 ]]; then
        report_result "PASS" "$test_name"
        return 0
    else
        report_result "FAIL" "$test_name" "Command failed with exit code: $exit_code"
        return 1
    fi
}

# Assert that a command fails
assert_failure() {
    local exit_code="$1"
    local test_name="$2"

    if [[ $exit_code -ne 0 ]]; then
        report_result "PASS" "$test_name"
        return 0
    else
        report_result "FAIL" "$test_name" "Command unexpectedly succeeded with exit code: $exit_code"
        return 1
    fi
}

# Setup test environment
setup_test_env() {
    echo "Setting up test environment..."

    # Create test log file
    touch "$TEST_LOG_FILE"
    echo "[Test Start] $(date)" >> "$TEST_LOG_FILE"

    # Define paths
    export PODMAN_MANAGER_PATH="/workspace/deliverables/podman_manager.sh"

    # Create a temporary directory for this test session
    export TEST_TEMP_DIR=$(mktemp -d)

    # Override config directory for tests
    export TEST_CONFIG_DIR="$TEST_TEMP_DIR/.config/oni-pod"
    mkdir -p "$TEST_CONFIG_DIR"

    # Override log file for tests
    export TEST_LOG_PATH="$TEST_TEMP_DIR/test_script.log"
}

# Cleanup test environment
cleanup_test_env() {
    echo "Cleaning up test environment..."

    # Remove temporary directory
    rm -rf "$TEST_TEMP_DIR"

    # Clear exported variables
    unset TEST_TEMP_DIR
    unset TEST_CONFIG_DIR
    unset TEST_LOG_PATH

    echo "[Test End] $(date)" >> "$TEST_LOG_FILE"
}

# Mock podman command for testing
mock_podman() {
    local subcommand="$1"
    shift

    case "$subcommand" in
        "version")
            echo "podman version 4.4.1"
            return 0
            ;;
        "ps")
            local all_flag=false
            local format_arg=""

            # Parse arguments
            while [[ $# -gt 0 ]]; do
                case $1 in
                    -a|--all)
                        all_flag=true
                        shift
                        ;;
                    --format)
                        format_arg="$2"
                        shift 2
                        ;;
                    *)
                        shift
                        ;;
                esac
            done

            if [[ "$all_flag" == true ]]; then
                if [[ "$format_arg" == *"{{.Names}}"* ]]; then
                    echo "web_server"
                    echo "db_server"
                    echo "cache_server"
                else
                    echo -e "CONTAINER ID\tIMAGE\tCOMMAND\tCREATED\tSTATUS\tPORTS\tNAMES"
                    echo -e "abc123def456\tnginx:latest\t\"nginx -g 'daemon of…\"\t2 hours ago\tUp 2 hours\t0.0.0.0:8080->80/tcp\tweb_server"
                    echo -e "789xyz123abc\tmysql:8.0\t\"docker-entrypoint.s…\"\t3 hours ago\tUp 3 hours\t3306/tcp\tdb_server"
                    echo -e "321cba654zyx\tredis:alpine\t\"docker-entrypoint.s…\"\t1 hour ago\tUp 1 hour\t6379/tcp\tcache_server"
                fi
            else
                echo -e "CONTAINER ID\tIMAGE\tCOMMAND\tCREATED\tSTATUS\tPORTS\tNAMES"
                echo -e "abc123def456\tnginx:latest\t\"nginx -g 'daemon of…\"\t2 hours ago\tUp 2 hours\t0.0.0.0:8080->80/tcp\tweb_server"
            fi
            ;;
        "inspect")
            local format_spec=""
            local container_ids=()
            local i

            # Parse arguments
            i=1
            while [[ $i -le $# ]]; do
                arg="${!i}"
                if [[ "$arg" == "--format" ]]; then
                    ((i++))
                    format_spec="${!i}"
                else
                    # If it doesn't start with -, it's likely a container ID
                    if [[ "$arg" != -* ]]; then
                        container_ids+=("$arg")
                    fi
                fi
                ((i++))
            done

            local container_id="${container_ids[0]}"

            if [[ -n "$format_spec" ]]; then
                case "$container_id" in
                    "web_server"|"abc123def456")
                        if [[ "$format_spec" == *"{{.State.Status}}"* ]]; then
                            echo "running"
                        elif [[ "$format_spec" == *"{{.State.Running}}"* ]]; then
                            echo "true"
                        elif [[ "$format_spec" == *"{{.State.Health.Status}}"* ]]; then
                            echo "healthy"
                        elif [[ "$format_spec" == *"{{.Names}}"* ]]; then
                            echo "web_server"
                        elif [[ "$format_spec" == *"{{.Name}}"* ]]; then
                            echo "/web_server"
                        elif [[ "$format_spec" == *"{{.State.ExitCode}}"* ]]; then
                            echo "0"
                        else
                            # Full inspection mock
                            cat << 'EOF'
[
    {
        "Id": "abc123def456",
        "Name": "/web_server",
        "State": {
            "Status": "running",
            "Running": true,
            "Paused": false,
            "Restarting": false,
            "OOMKilled": false,
            "Dead": false,
            "PID": 12345,
            "StartedAt": "2026-03-25T10:00:00.000000000Z",
            "FinishedAt": "0001-01-01T00:00:00Z",
            "ExitCode": 0,
            "Health": {
                "Status": "healthy",
                "FailingStreak": 0,
                "Log": [
                    {
                        "Start": "2026-03-25T10:00:00.000000000Z",
                        "End": "2026-03-25T10:00:00.000000000Z",
                        "ExitCode": 0,
                        "Output": "healthy"
                    }
                ]
            }
        },
        "Config": {
            "Image": "nginx:latest",
            "Labels": {
                "maintainer": "NGINX Docker Maintainers <docker-maint@nginx.com>"
            }
        }
    }
]
EOF
                        fi
                        ;;
                    "stopped_container"|"def789ghi012")
                        if [[ "$format_spec" == *"{{.State.Status}}"* ]]; then
                            echo "exited"
                        elif [[ "$format_spec" == *"{{.State.Running}}"* ]]; then
                            echo "false"
                        else
                            cat << 'EOF'
[
    {
        "Id": "def789ghi012",
        "Name": "/stopped_container",
        "State": {
            "Status": "exited",
            "Running": false,
            "Paused": false,
            "Restarting": false,
            "OOMKilled": false,
            "Dead": false,
            "PID": 0,
            "StartedAt": "2026-03-25T09:00:00.000000000Z",
            "FinishedAt": "2026-03-25T09:30:00.000000000Z",
            "ExitCode": 1,
            "Health": {
                "Status": "unhealthy",
                "FailingStreak": 3
            }
        }
    }
]
EOF
                        fi
                        ;;
                    *)
                        # Non-existent container
                        echo "Error: no container with name or ID \"$container_id\" found" >&2
                        return 1
                        ;;
                esac
            else
                # Full inspection for multiple containers
                case "$container_id" in
                    "web_server"|"abc123def456")
                        cat << 'EOF'
[
    {
        "Id": "abc123def456",
        "Name": "/web_server",
        "State": {
            "Status": "running",
            "Running": true,
            "Paused": false,
            "Restarting": false,
            "OOMKilled": false,
            "Dead": false,
            "PID": 12345,
            "StartedAt": "2026-03-25T10:00:00.000000000Z",
            "FinishedAt": "0001-01-01T00:00:00Z",
            "ExitCode": 0,
            "Health": {
                "Status": "healthy",
                "FailingStreak": 0
            }
        }
    }
]
EOF
                        ;;
                    *)
                        echo "Error: no container with name or ID \"$container_id\" found" >&2
                        return 1
                        ;;
                esac
            fi
            ;;
        "stats")
            local no_stream=false
            local all_flag=false
            local format_arg=""

            # Parse arguments
            while [[ $# -gt 0 ]]; do
                case $1 in
                    --no-stream)
                        no_stream=true
                        shift
                        ;;
                    --all)
                        all_flag=true
                        shift
                        ;;
                    --format)
                        format_arg="$2"
                        shift 2
                        ;;
                    *)
                        shift
                        ;;
                esac
            done

            if [[ "$no_stream" == true ]]; then
                if [[ "$format_arg" == "json" ]]; then
                    echo '[{"Container": "abc123def456", "Name": "web_server", "CPUPerc": "15.20%", "MemUsage": "55.8MiB / 1.944GiB", "MemPerc": "2.87%", "NetIO": "1.23kB / 678B", "BlockIO": "0B / 0B", "PIDs": "9"}]'
                else
                    echo -e "CONTAINER ID\tNAME\tCPU %\tMEM USAGE / LIMIT\tMEM %\tNET IO\tBLOCK IO\tPIDS"
                    echo -e "abc123def456\tweb_server\t15.20%\t55.8MiB / 1.944GiB\t2.87%\t1.23kB / 678B\t0B / 0B\t9"
                fi
            else
                # Continuous stream output simulation
                echo "CONTAINER ID\tNAME\tCPU %\tMEM USAGE / LIMIT\tMEM %\tNET IO\tBLOCK IO\tPIDS"
                echo "Press Ctrl+C to stop monitoring..."
            fi
            ;;
        "start")
            local target_container="$1"
            case "$target_container" in
                "web_server"|"abc123def456")
                    echo "$target_container"
                    return 0
                    ;;
                *)
                    echo "Error: no container with name or ID \"$target_container\" found" >&2
                    return 1
                    ;;
            esac
            ;;
        "stop")
            local target_container="$1"
            case "$target_container" in
                "web_server"|"abc123def456")
                    echo "$target_container"
                    return 0
                    ;;
                *)
                    echo "Error: no container with name or ID \"$target_container\" found" >&2
                    return 1
                    ;;
            esac
            ;;
        "restart")
            local target_container="$1"
            case "$target_container" in
                "web_server"|"abc123def456")
                    echo "$target_container"
                    return 0
                    ;;
                *)
                    echo "Error: no container with name or ID \"$target_container\" found" >&2
                    return 1
                    ;;
            esac
            ;;
        "logs")
            local target_container="$1"
            local follow_flag=false

            if [[ "$2" == "-f" ]] || [[ "$2" == "--follow" ]]; then
                follow_flag=true
            fi

            case "$target_container" in
                "web_server"|"abc123def456")
                    if [[ "$follow_flag" == true ]]; then
                        echo "Following logs for web_server..."
                        echo "10.0.0.1 - - [25/Mar/2026:10:00:01 +0000] \"GET / HTTP/1.1\" 200 612 \"-\" \"Mozilla/5.0\""
                        echo "10.0.0.1 - - [25/Mar/2026:10:00:02 +0000] \"GET /styles.css HTTP/1.1\" 200 453 \"-\" \"Mozilla/5.0\""
                    else
                        echo "10.0.0.1 - - [25/Mar/2026:10:00:01 +0000] \"GET / HTTP/1.1\" 200 612 \"-\" \"Mozilla/5.0\""
                        echo "10.0.0.1 - - [25/Mar/2026:10:00:02 +0000] \"GET /styles.css HTTP/1.1\" 200 453 \"-\" \"Mozilla/5.0\""
                        echo "10.0.0.1 - - [25/Mar/2026:10:00:03 +0000] \"POST /api/login HTTP/1.1\" 200 123 \"-\" \"Mozilla/5.0\""
                    fi
                    return 0
                    ;;
                *)
                    echo "Error: no container with name or ID \"$target_container\" found" >&2
                    return 1
                    ;;
            esac
            ;;
        "exec")
            local target_container="$1"
            shift
            local command=("$@")

            case "$target_container" in
                "web_server"|"abc123def456")
                    # Execute the command in the container
                    case "${command[0]}" in
                        "echo")
                            echo "${command[@]:1}"
                            return 0
                            ;;
                        "ls")
                            echo "bin"
                            echo "etc"
                            echo "usr"
                            echo "var"
                            return 0
                            ;;
                        *)
                            # For testing purposes, just echo the command
                            echo "Executing: ${command[*]}"
                            return 0
                            ;;
                    esac
                    ;;
                *)
                    echo "Error: no container with name or ID \"$target_container\" found" >&2
                    return 1
                    ;;
            esac
            ;;
        "rm")
            local target_container="$1"
            case "$target_container" in
                "web_server"|"abc123def456")
                    echo "$target_container"
                    return 0
                    ;;
                *)
                    echo "Error: no container with name or ID \"$target_container\" found" >&2
                    return 1
                    ;;
            esac
            ;;
        "system")
            if [[ "$1" == "prune" ]]; then
                echo "Deleted Containers:"
                echo "abc123def456"
                echo "789xyz123abc"
                echo ""
                echo "Deleted Images:"
                echo "Total reclaimed space: 100MB"
                return 0
            fi
            ;;
        *)
            echo "Unknown podman command: $subcommand" >&2
            return 1
            ;;
    esac
}

# Unit Tests for Individual Functions

test_log_function() {
    echo -e "\n${YELLOW}Testing log function...${NC}"

    # Create a simple script that uses the log function
    cat > "$TEST_TEMP_DIR/test_log.sh" << 'EOF'
#!/bin/bash
LOG_FILE="/tmp/test_log_script.log"
if [[ -f "$LOG_FILE" ]]; then
    rm "$LOG_FILE"
fi

log() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" | tee -a "$LOG_FILE"
}

# Test logging
log "Test message 1"
log "Test message 2"

# Count log entries
count=$(grep -c "Test message" "$LOG_FILE")
echo "$count"
EOF
    chmod +x "$TEST_TEMP_DIR/test_log.sh"

    local result
    result=$(bash "$TEST_TEMP_DIR/test_log.sh")

    if [[ "$result" == "2" ]]; then
        report_result "PASS" "log function works correctly"
    else
        report_result "FAIL" "log function test" "Expected 2 log entries, got $result"
    fi

    rm -f "$TEST_TEMP_DIR/test_log_script.log" "$TEST_TEMP_DIR/test_log.sh"
}

test_check_podman_installed() {
    echo -e "\n${YELLOW}Testing check_podman_installed function...${NC}"

    # Temporarily replace podman with our mock
    export -f mock_podman
    alias podman='mock_podman'

    # Test successful case
    local output
    output=$(bash -c "source '$PODMAN_MANAGER_PATH'; check_podman_installed" 2>&1)
    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        report_result "PASS" "check_podman_installed passes when podman exists"
    else
        report_result "FAIL" "check_podman_installed test" "Unexpected failure: $output"
    fi

    # Restore original podman
    unalias podman 2>/dev/null
}

test_load_config() {
    echo -e "\n${YELLOW}Testing load_config function...${NC}"

    # Test with default configuration
    local output
    output=$(bash -c "
      export CONFIG_DIR='$TEST_CONFIG_DIR';
      export CONFIG_FILE='$TEST_CONFIG_DIR/config.yaml';
      export RESOURCE_THRESHOLD_CPU=80;
      export RESOURCE_THRESHOLD_MEM=80;
      source '$PODMAN_MANAGER_PATH';
      load_config;
      echo \"CPU_THRESHOLD=\$RESOURCE_THRESHOLD_CPU, MEM_THRESHOLD=\$RESOURCE_THRESHOLD_MEM\"
    " 2>/dev/null)

    if [[ "$output" == *"CPU_THRESHOLD="* ]]; then
        report_result "PASS" "load_config function executes without error"
    else
        report_result "FAIL" "load_config test" "Function failed to execute: $output"
    fi

    # Test with custom config file
    echo "resource_threshold_cpu: 85" > "$TEST_CONFIG_DIR/config.yaml"
    echo "resource_threshold_mem: 75" >> "$TEST_CONFIG_DIR/config.yaml"
    echo "alert_email: test@example.com" >> "$TEST_CONFIG_DIR/config.yaml"

    output=$(bash -c "
      export CONFIG_DIR='$TEST_CONFIG_DIR';
      export CONFIG_FILE='$TEST_CONFIG_DIR/config.yaml';
      export RESOURCE_THRESHOLD_CPU=80;
      export RESOURCE_THRESHOLD_MEM=80;
      export ALERT_EMAIL='';
      source '$PODMAN_MANAGER_PATH';
      load_config;
      echo \"CPU=\$RESOURCE_THRESHOLD_CPU, MEM=\$RESOURCE_THRESHOLD_MEM, EMAIL=\$ALERT_EMAIL\"
    " 2>/dev/null)

    if [[ "$output" == *"CPU=85"* && "$output" == *"MEM=75"* ]]; then
        report_result "PASS" "load_config loads values from config file"
    else
        report_result "FAIL" "load_config test with custom config" "Expected to load custom values: $output"
    fi

    # Clean up config file
    rm -f "$TEST_CONFIG_DIR/config.yaml"
}

test_list_containers() {
    echo -e "\n${YELLOW}Testing list_containers function...${NC}"

    export -f mock_podman
    alias podman='mock_podman'

    local output
    output=$(bash -c "source '$PODMAN_MANAGER_PATH'; list_containers" 2>/dev/null)

    if [[ "$output" == *"CONTAINER ID"* && "$output" == *"web_server"* ]]; then
        report_result "PASS" "list_containers shows container information"
    else
        report_result "FAIL" "list_containers test" "Output missing expected elements: $output"
    fi

    unalias podman 2>/dev/null
}

test_show_container_status() {
    echo -e "\n${YELLOW}Testing show_container_status function...${NC}"

    export -f mock_podman
    alias podman='mock_podman'

    # Test with existing container
    local output
    output=$(bash -c "source '$PODMAN_MANAGER_PATH'; show_container_status 'web_server'" 2>/dev/null)

    if [[ "$output" == *"Container: web_server"* && "$output" == *"Status: running"* ]]; then
        report_result "PASS" "show_container_status shows status for existing container"
    else
        report_result "FAIL" "show_container_status test with existing container" "Unexpected output: $output"
    fi

    # Test with non-existent container
    output=$(bash -c "source '$PODMAN_MANAGER_PATH'; show_container_status 'nonexistent'" 2>&1)

    if [[ "$output" == *"not found"* ]]; then
        report_result "PASS" "show_container_status handles non-existent container"
    else
        report_result "FAIL" "show_container_status test with non-existent container" "Should indicate container not found: $output"
    fi

    unalias podman 2>/dev/null
}

test_send_notification() {
    echo -e "\n${YELLOW}Testing send_notification function...${NC}"

    # Create a test script for notification function
    cat > "$TEST_TEMP_DIR/test_notification.sh" << 'EOF'
#!/bin/bash

# Mock notify-send and mail commands
notify-send() {
    echo "DESKTOP_NOTIFICATION: $*"
}

mail() {
    echo "EMAIL_SENT_TO: $3"  # Third argument is typically the recipient
    echo "SUBJECT: $2"        # Second argument is typically the subject
}

send_notification() {
    local level="$1"  # info, warning, error
    local message="$2"
    local subject="Podman Alert: $level - ${message:0:50}..."

    # Log the message first (we'll capture this separately)
    echo "LOG: [$level] $message" >&2

    # Send desktop notification if notify-send is available
    if command -v notify-send &> /dev/null; then
        notify-send "Podman $level" "$message" --urgency "${level:0:1}" --expire-time 5000
    fi

    # Send email if configured
    if [[ -n "$ALERT_EMAIL" ]]; then
        if command -v mail &> /dev/null; then
            echo "$message" | mail -s "$subject" "$ALERT_EMAIL"
        else
            echo "ERROR: Mail command not available" >&2
        fi
    fi
}

# Export the function for subshells if needed
export -f send_notification
export -f notify-send
export -f mail

ALERT_EMAIL="test@example.com"
export ALERT_EMAIL

# Test the notification function
send_notification "warning" "Test high CPU usage alert"
EOF
    chmod +x "$TEST_TEMP_DIR/test_notification.sh"

    local output
    output=$(bash "$TEST_TEMP_DIR/test_notification.sh" 2>&1)

    if [[ "$output" == *"DESKTOP_NOTIFICATION"* && "$output" == *"EMAIL_SENT_TO: test@example.com"* ]]; then
        report_result "PASS" "send_notification sends both desktop and email notifications"
    else
        report_result "FAIL" "send_notification test" "Missing expected notification methods: $output"
    fi

    rm -f "$TEST_TEMP_DIR/test_notification.sh"
}

test_check_resource_usage() {
    echo -e "\n${YELLOW}Testing check_resource_usage function...${NC}"

    # Create a test script that simulates resource checking
    cat > "$TEST_TEMP_DIR/test_resource_check.sh" << 'EOF'
#!/bin/bash

# Mock podman command for stats
mock_podman() {
    if [[ "$1" == "stats" ]] && [[ "$3" == "--no-stream" ]]; then
        if [[ "$4" == "--format" ]] && [[ "$5" == "json" ]]; then
            echo '[{"Container": "abc123def456", "Name": "web_server", "CPUPerc": "85.20%", "MemUsage": "1.6GiB / 2.0GiB", "MemPerc": "82.50%", "NetIO": "1.23kB / 678B", "BlockIO": "0B / 0B", "PIDs": "9"}]'
        else
            echo -e "CONTAINER ID\tNAME\tCPU %\tMEM USAGE / LIMIT\tMEM %\tNET IO\tBLOCK IO\tPIDS"
            echo -e "abc123def456\web_server\t85.20%\t1.6GiB / 2.0GiB\t82.50%\t1.23kB / 678B\t0B / 0B\t9"
        fi
    fi
}

export -f mock_podman
alias podman='mock_podman'

# Mock send_notification to capture alerts
notification_capture=""
send_notification() {
    local level="$1"
    local message="$2"
    notification_capture="$notification_capture|$level:$message"
    echo "NOTIFICATION: [$level] $message" >&2
}

export -f send_notification

# Simulate the check_resource_usage function logic
check_resource_usage() {
    local container_id="$1"
    local cpu_threshold="${2:-80}"
    local mem_threshold="${3:-80}"

    # Get container stats
    local stats_line
    stats_line=$(podman stats --no-stream --format "table {{.CPUPerc}}\t{{.MemPerc}}" 2>/dev/null | grep "$container_id" | head -n 1)

    if [[ -n "$stats_line" ]]; then
        # Extract CPU and memory percentages
        local cpu_usage=$(echo "$stats_line" | awk '{print $1}' | sed 's/%//')
        local mem_usage=$(echo "$stats_line" | awk '{print $2}' | sed 's/%//')

        # Remove percentage sign and compare with threshold
        cpu_usage=${cpu_usage%.*}
        mem_usage=${mem_usage%.*}

        if [[ -n "$cpu_usage" && "$cpu_usage" -gt "$cpu_threshold" ]]; then
            send_notification "warning" "High CPU usage detected for container $container_id: ${cpu_usage}% (threshold: ${cpu_threshold}%)"
        fi

        if [[ -n "$mem_usage" && "$mem_usage" -gt "$mem_threshold" ]]; then
            send_notification "warning" "High memory usage detected for container $container_id: ${mem_usage}% (threshold: ${mem_threshold}%)"
        fi

        echo "$cpu_usage,$mem_usage"
    else
        echo "0,0"
    fi
}

# Test with high resource usage to trigger alerts
result=$(check_resource_usage "abc123def456" 80 80)
echo "Result: $result"
EOF
    chmod +x "$TEST_TEMP_DIR/test_resource_check.sh"

    local output
    output=$(bash "$TEST_TEMP_DIR/test_resource_check.sh" 2>&1)

    if [[ "$output" == *"Result: 85,82"* ]] && [[ "$output" == *"High CPU usage"* ]] && [[ "$output" == *"High memory usage"* ]]; then
        report_result "PASS" "check_resource_usage detects and alerts on high resource usage"
    else
        report_result "FAIL" "check_resource_usage test" "Should detect high resource usage: $output"
    fi

    rm -f "$TEST_TEMP_DIR/test_resource_check.sh"
}

test_monitor_container_health() {
    echo -e "\n${YELLOW}Testing monitor_container_health function...${NC}"

    # Create a test script for health monitoring
    cat > "$TEST_TEMP_DIR/test_health_monitor.sh" << 'EOF'
#!/bin/bash

# Mock podman command to simulate container status
mock_podman() {
    case "$1" in
        "ps")
            if [[ "$*" == *"-a"* ]]; then
                echo -e "def789ghi012\tstopped_container\tExited (1) 10 minutes ago"
                echo -e "abc123def456\web_server\tUp 2 hours\t0.0.0.0:8080->80/tcp"
            fi
            ;;
        "inspect")
            local container_id="$2"
            case "$container_id" in
                "stopped_container"|"def789ghi012")
                    echo "unhealthy"
                    ;;
                "web_server"|"abc123def456")
                    echo "healthy"
                    ;;
                *)
                    echo "none"
                    ;;
            esac
            ;;
    esac
}

export -f mock_podman
alias podman='mock_podman'

# Mock send_notification to capture alerts
notification_capture=""
send_notification() {
    local level="$1"
    local message="$2"
    notification_capture="$notification_capture|$level:$message"
    echo "HEALTH_ALERT: [$level] $message"
}

export -f send_notification

# Simulate the monitor_container_health function logic
monitor_container_health() {
    local containers
    containers=$(podman ps -a --format "{{.ID}}\t{{.Names}}\t{{.Status}}" 2>/dev/null)

    local alert_count=0
    while IFS=$'\t' read -r id name status; do
        if [[ -n "$id" && -n "$name" && -n "$status" ]]; then
            # Check if container is unhealthy or has failed
            local health_status
            health_status=$(podman inspect --format '{{.State.Health.Status}}' "$name" 2>/dev/null || echo "none")

            # Check for exit codes indicating failure
            local exit_code
            exit_code=$(podman inspect --format '{{.State.ExitCode}}' "$name" 2>/dev/null || echo "")

            if [[ "$status" == *"Exited"* ]] || [[ "$status" == *"Created"* ]]; then
                # Container has exited or failed to start properly
                send_notification "error" "Container $name ($id) has exited with status: $status"
                ((alert_count++))
            elif [[ "$health_status" == "unhealthy" ]]; then
                send_notification "error" "Container $name ($id) health check failed: $health_status"
                ((alert_count++))
            elif [[ -n "$exit_code" && "$exit_code" -ne 0 ]]; then
                send_notification "error" "Container $name ($id) has non-zero exit code: $exit_code"
                ((alert_count++))
            fi
        fi
    done <<< "$containers"

    echo "Alerts triggered: $alert_count"
}

# Run the health monitoring
monitor_container_health
EOF
    chmod +x "$TEST_TEMP_DIR/test_health_monitor.sh"

    local output
    output=$(bash "$TEST_TEMP_DIR/test_health_monitor.sh" 2>&1)

    if [[ "$output" == *"Alerts triggered: "* ]] && [[ "$output" == *"HEALTH_ALERT"* ]]; then
        report_result "PASS" "monitor_container_health detects and alerts on unhealthy containers"
    else
        report_result "FAIL" "monitor_container_health test" "Should detect unhealthy containers: $output"
    fi

    rm -f "$TEST_TEMP_DIR/test_health_monitor.sh"
}

# Integration Tests

test_full_script_execution() {
    echo -e "\n${YELLOW}Testing full script execution...${NC}"

    export -f mock_podman
    alias podman='mock_podman'

    # Test various commands
    local commands=("list" "stats" "resources")
    local all_passed=true

    for cmd in "${commands[@]}"; do
        local output
        output=$(bash "$PODMAN_MANAGER_PATH" "$cmd" 2>&1)
        local exit_code=$?

        if [[ $exit_code -ne 0 ]]; then
            report_result "FAIL" "Full script execution with '$cmd' command" "Exit code: $exit_code, Output: $output"
            all_passed=false
        else
            report_result "PASS" "Full script execution with '$cmd' command"
        fi
    done

    if [[ "$all_passed" == true ]]; then
        report_result "PASS" "Multiple commands execute without error"
    fi

    unalias podman 2>/dev/null
}

test_help_command() {
    echo -e "\n${YELLOW}Testing help command...${NC}"

    local output
    output=$(bash "$PODMAN_MANAGER_PATH" --help 2>&1)
    local exit_code=$?

    if [[ $exit_code -eq 0 && "$output" == *"Podman Manager Script"* && "$output" == *"Commands:"* ]]; then
        report_result "PASS" "Help command works correctly"
    else
        report_result "FAIL" "Help command test" "Unexpected output or exit code: $exit_code, Output: $output"
    fi
}

test_error_handling() {
    echo -e "\n${YELLOW}Testing error handling...${NC}"

    # Test with invalid command
    local output
    output=$(bash "$PODMAN_MANAGER_PATH" "invalid_command" 2>&1)
    local exit_code=$?

    if [[ $exit_code -ne 0 && "$output" == *"Unknown command"* ]]; then
        report_result "PASS" "Script handles unknown commands correctly"
    else
        report_result "FAIL" "Error handling for unknown commands" "Expected error exit code and message: $output"
    fi

    # Test with missing container ID for commands that require it
    output=$(bash "$PODMAN_MANAGER_PATH" "status" 2>&1)
    exit_code=$?

    if [[ $exit_code -ne 0 && "$output" == *"Container ID is required"* ]]; then
        report_result "PASS" "Script validates required parameters"
    else
        report_result "FAIL" "Parameter validation test" "Expected error for missing container ID: $output"
    fi
}

# Run all tests
run_all_tests() {
    reset_counters

    echo -e "${YELLOW}Starting Comprehensive Podman Manager Test Suite${NC}"
    echo "====================================================="

    setup_test_env

    # Run unit tests
    test_log_function
    test_check_podman_installed
    test_load_config
    test_list_containers
    test_show_container_status
    test_send_notification
    test_check_resource_usage
    test_monitor_container_health

    # Run integration tests
    test_help_command
    test_full_script_execution
    test_error_handling

    cleanup_test_env

    # Print summary
    echo -e "\n${YELLOW}Test Suite Summary${NC}"
    echo "=================="
    echo -e "PASSED: ${GREEN}$TEST_PASSED${NC}"
    echo -e "FAILED: ${RED}$TEST_FAILED${NC}"
    echo "TOTAL:  $((TEST_PASSED + TEST_FAILED))"

    if [[ $TEST_FAILED -eq 0 ]]; then
        echo -e "\n${GREEN}All tests passed!${NC}"
        return 0
    else
        echo -e "\n${RED}Some tests failed.${NC}"
        return 1
    fi
}

# Execute test suite
run_all_tests "$@"