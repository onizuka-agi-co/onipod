#!/bin/bash

# Oni Pod Monitoring and Logging System
# Implements monitoring and logging as specified in the design document

set -euo pipefail

LOG_DIR="${HOME}/.local/share/oni-pod/logs"
STATE_DIR="${HOME}/.local/share/oni-pod/state"
CONFIG_FILE="${HOME}/.config/oni-pod/config.yaml"

# Ensure directories exist
mkdir -p "$LOG_DIR" "$STATE_DIR"

# Logging function
log_message() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "${LOG_DIR}/monitoring.log"
}

# Collect metrics for a specific container
collect_metrics() {
    local container_name="$1"

    if [[ -z "$container_name" ]]; then
        log_message "ERROR" "Container name is required"
        return 1
    fi

    # Check if container exists
    if ! podman inspect "$container_name" > /dev/null 2>&1; then
        log_message "ERROR" "Container '$container_name' does not exist"
        return 1
    fi

    # Get container stats
    local stats_json
    stats_json=$(podman stats --no-stream --format json "$container_name" 2>/dev/null || echo "[]")

    if [[ "$stats_json" == "[]" ]]; then
        log_message "WARNING" "Could not get stats for container '$container_name'"
        return 1
    fi

    # Parse and display metrics
    echo "$stats_json" | jq -r '
        .[] |
        "Container: " + .Container +
        "\nCPU Usage: " + .CPUPerc +
        "\nMemory Usage: " + .MemUsage + " (" + .MemPerc + ")" +
        "\nNetwork I/O: " + .NetIO +
        "\nBlock I/O: " + .BlockIO +
        "\nPID Count: " + .PIDs'
}

# Monitor all containers continuously
monitor_all_containers() {
    local interval="${1:-30}"  # Default to 30 seconds

    log_message "INFO" "Starting continuous monitoring (interval: ${interval}s)"

    echo "Starting container monitoring (Press Ctrl+C to stop)..."
    trap 'echo -e "\nMonitoring stopped."; exit 0' INT TERM

    while true; do
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        echo "=== Metrics collected at $timestamp ==="

        # Get all containers (running and stopped)
        local containers=$(podman ps -a --format "{{.Names}}" 2>/dev/null)

        if [[ -n "$containers" ]]; then
            while IFS= read -r container; do
                if [[ -n "$container" ]]; then
                    echo "--- Container: $container ---"

                    # Get container status
                    local status=$(podman inspect --format '{{.State.Status}}' "$container" 2>/dev/null || echo "unknown")
                    echo "Status: $status"

                    # Only collect detailed metrics for running containers
                    if [[ "$status" == "running" ]]; then
                        local stats_json
                        stats_json=$(podman stats --no-stream --format json "$container" 2>/dev/null || echo "[]")

                        if [[ "$stats_json" != "[]" ]]; then
                            echo "$stats_json" | jq -r '
                                .[] |
                                "CPU: " + .CPUPerc +
                                ", Mem: " + .MemUsage + " (" + .MemPerc + ")" +
                                ", Net: " + .NetIO +
                                ", Block: " + .BlockIO +
                                ", PIDs: " + .PIDs'
                        else
                            echo "Metrics: unavailable"
                        fi
                    else
                        echo "Metrics: not collected (container not running)"
                    fi
                    echo ""
                fi
            done <<< "$containers"
        else
            echo "No containers found."
        fi

        sleep "$interval"
    done
}

# Perform health check on all containers
health_check_all() {
    log_message "INFO" "Performing health check on all containers"

    local containers=$(podman ps -a --format "{{.Names}}" 2>/dev/null)
    local unhealthy_count=0
    local total_count=0

    if [[ -n "$containers" ]]; then
        while IFS= read -r container; do
            if [[ -n "$container" ]]; then
                ((total_count++))

                local status=$(podman inspect --format '{{.State.Status}}' "$container" 2>/dev/null || echo "unknown")
                local health_status=$(podman inspect --format '{{.State.Health.Status}}' "$container" 2>/dev/null || echo "none")

                echo "Container: $container"
                echo "  Status: $status"

                if [[ "$health_status" != "none" ]]; then
                    echo "  Health: $health_status"

                    if [[ "$health_status" != "healthy" ]]; then
                        echo "  ⚠️  Warning: Container health status is $health_status"
                        ((unhealthy_count++))
                    fi
                else
                    # If no health check is configured, check if it's running
                    if [[ "$status" == "running" ]]; then
                        echo "  Status: running (no health check configured)"
                    else
                        echo "  ⚠️  Warning: Container is not running"
                        ((unhealthy_count++))
                    fi
                fi

                echo ""
            fi
        done <<< "$containers"
    else
        echo "No containers found."
    fi

    echo "Health check summary:"
    echo "  Total containers checked: $total_count"
    echo "  Unhealthy containers: $unhealthy_count"

    if [[ $unhealthy_count -gt 0 ]]; then
        log_message "WARNING" "Found $unhealthy_count unhealthy containers out of $total_count total"
        return 1
    else
        log_message "INFO" "All containers are healthy"
        return 0
    fi
}

# Perform health check on a specific container
health_check_single() {
    local container_name="$1"

    if [[ -z "$container_name" ]]; then
        log_message "ERROR" "Container name is required"
        return 1
    fi

    # Check if container exists
    if ! podman inspect "$container_name" > /dev/null 2>&1; then
        log_message "ERROR" "Container '$container_name' does not exist"
        return 1
    fi

    local status=$(podman inspect --format '{{.State.Status}}' "$container_name" 2>/dev/null || echo "unknown")
    local health_status=$(podman inspect --format '{{.State.Health.Status}}' "$container_name" 2>/dev/null || echo "none")

    echo "Health check for container: $container_name"
    echo "  Status: $status"

    if [[ "$health_status" != "none" ]]; then
        echo "  Health: $health_status"

        if [[ "$health_status" == "healthy" ]]; then
            log_message "INFO" "Container '$container_name' is healthy"
            return 0
        else
            log_message "WARNING" "Container '$container_name' health status is $health_status"
            return 1
        fi
    else
        # If no health check is configured, just check if it's running
        if [[ "$status" == "running" ]]; then
            echo "  Status: running (no health check configured)"
            log_message "INFO" "Container '$container_name' is running"
            return 0
        else
            echo "  ❌ Container is not running"
            log_message "WARNING" "Container '$container_name' is not running"
            return 1
        fi
    fi
}

# Aggregate logs from all containers
aggregate_logs() {
    local container_name="$1"
    local lines="${2:-50}"  # Default to last 50 lines

    if [[ -n "$container_name" ]]; then
        # Specific container logs
        log_message "INFO" "Fetching logs for container: $container_name"

        if podman logs "$container_name" 2>/dev/null; then
            return 0
        else
            log_message "ERROR" "Could not fetch logs for container '$container_name'"
            return 1
        fi
    else
        # All containers logs
        log_message "INFO" "Aggregating logs from all containers"

        local containers=$(podman ps -a --format "{{.Names}}" 2>/dev/null)

        if [[ -n "$containers" ]]; then
            while IFS= read -r container; do
                if [[ -n "$container" ]]; then
                    echo "=== Logs for container: $container ==="
                    podman logs --tail "$lines" "$container" 2>/dev/null || echo "No logs available for $container"
                    echo ""
                fi
            done <<< "$containers"
        else
            echo "No containers found."
        fi
    fi
}

# Alert notification system (placeholder)
send_alert() {
    local severity="$1"
    local message="$2"

    log_message "ALERT" "[$severity] $message"

    # In a real implementation, this could send notifications via email, webhook, etc.
    # For now, just log the alert
    echo "Alert sent: [$severity] $message"
}

# Monitor resource usage trends over time
monitor_resource_trends() {
    local duration="${1:-300}"  # Duration in seconds, default 5 minutes
    local interval="${2:-30}"   # Interval in seconds, default 30 seconds
    local output_file="${STATE_DIR}/resource_trends.json"

    log_message "INFO" "Monitoring resource trends for ${duration}s (sample every ${interval}s)"

    # Calculate number of iterations
    local iterations=$((duration / interval))

    # Initialize the output file
    echo "[" > "$output_file"

    for i in $(seq 1 $iterations); do
        local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)

        # Get stats for all running containers
        local stats_json
        stats_json=$(podman stats --no-stream --format json 2>/dev/null || echo "[]")

        # Add timestamp to the data
        local enriched_stats=$(echo "$stats_json" | jq --arg ts "$timestamp" '.[].timestamp = $ts')

        if [[ "$enriched_stats" != "[]" ]]; then
            if [[ $i -gt 1 ]]; then
                echo "," >> "$output_file"
            fi
            echo "$enriched_stats" | jq '.' >> "$output_file"
        fi

        sleep "$interval"
    done

    echo "]" >> "$output_file"

    log_message "INFO" "Resource trend data saved to $output_file"

    # Print summary
    local container_count=$(jq '.[][] | select(.timestamp) | .Container' "$output_file" 2>/dev/null | sort -u | wc -l)
    echo "Monitored $container_count unique containers over ${duration}s"
}

# Main function
main() {
    local command="$1"
    shift

    case "$command" in
        metrics)
            collect_metrics "$@"
            ;;
        monitor-all)
            monitor_all_containers "$@"
            ;;
        health-check-all)
            health_check_all
            ;;
        health-check)
            health_check_single "$@"
            ;;
        aggregate-logs)
            aggregate_logs "$@"
            ;;
        resource-trends)
            monitor_resource_trends "$@"
            ;;
        *)
            echo "Oni Pod Monitoring and Logging System"
            echo ""
            echo "Usage: $0 <command> [options]"
            echo ""
            echo "Commands:"
            echo "  metrics CONTAINER_NAME           Get metrics for a container"
            echo "  monitor-all [INTERVAL]          Continuously monitor all containers (default 30s)"
            echo "  health-check-all               Perform health check on all containers"
            echo "  health-check CONTAINER_NAME    Perform health check on specific container"
            echo "  aggregate-logs [CONTAINER] [LINES]  Get logs from containers (default: all containers, last 50 lines)"
            echo "  resource-trends DURATION INTERVAL  Monitor resource trends over time (duration in sec, default 300; interval in sec, default 30)"
            echo ""
            echo "Examples:"
            echo "  $0 metrics my-container"
            echo "  $0 monitor-all 60              # Monitor every 60 seconds"
            echo "  $0 health-check my-container"
            echo "  $0 aggregate-logs              # Get logs from all containers"
            echo "  $0 aggregate-logs my-container 100  # Get last 100 lines from specific container"
            return 1
            ;;
    esac
}

main "$@"