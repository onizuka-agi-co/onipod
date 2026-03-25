#!/bin/bash

# Podman Manager Script
# This script provides monitoring and management functions for Podman containers.

set -euo pipefail  # Exit on error, undefined variables, and pipe failures

readonly SCRIPT_NAME=$(basename "$0")
readonly LOG_FILE="/tmp/${SCRIPT_NAME}.log"

# Logging function
log() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" | tee -a "$LOG_FILE"
}

# Print help information
print_help() {
    cat << EOF
Podman Manager Script

Usage: $SCRIPT_NAME [COMMAND] [OPTIONS]

Commands:
    list                    List all containers
    status CONTAINER_ID     Show status of specific container
    start CONTAINER_ID      Start a container
    stop CONTAINER_ID       Stop a container
    restart CONTAINER_ID    Restart a container
    logs CONTAINER_ID       Show logs of a container
    monitor               Monitor all containers continuously
    health-check            Perform health check on all containers

Options:
    -h, --help              Show this help message

Examples:
    $SCRIPT_NAME list
    $SCRIPT_NAME start my-container
    $SCRIPT_NAME monitor
EOF
}

# Check if podman is installed
check_podman_installed() {
    if ! command -v podman &> /dev/null; then
        log "ERROR: podman is not installed"
        exit 1
    fi
}

# List all containers
list_containers() {
    log "Listing all containers..."
    podman ps -a
}

# Show status of a specific container
show_container_status() {
    local container_id="$1"
    if [[ -z "$container_id" ]]; then
        log "ERROR: Container ID is required"
        exit 1
    fi

    log "Checking status of container: $container_id"
    podman ps -f id="$container_id"
}

# Start a container
start_container() {
    local container_id="$1"
    if [[ -z "$container_id" ]]; then
        log "ERROR: Container ID is required"
        exit 1
    fi

    log "Starting container: $container_id"
    podman start "$container_id"
    log "Container $container_id started successfully"
}

# Stop a container
stop_container() {
    local container_id="$1"
    if [[ -z "$container_id" ]]; then
        log "ERROR: Container ID is required"
        exit 1
    fi

    log "Stopping container: $container_id"
    podman stop "$container_id"
    log "Container $container_id stopped successfully"
}

# Restart a container
restart_container() {
    local container_id="$1"
    if [[ -z "$container_id" ]]; then
        log "ERROR: Container ID is required"
        exit 1
    fi

    log "Restarting container: $container_id"
    podman restart "$container_id"
    log "Container $container_id restarted successfully"
}

# Show logs of a container
show_logs() {
    local container_id="$1"
    if [[ -z "$container_id" ]]; then
        log "ERROR: Container ID is required"
        exit 1
    fi

    log "Showing logs for container: $container_id"
    podman logs "$container_id"
}

# Monitor containers continuously
monitor_containers() {
    log "Starting container monitoring..."

    while true; do
        echo "=================================="
        echo "Container Status - $(date)"
        echo "=================================="
        podman ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"
        echo ""

        sleep 10  # Wait for 10 seconds before next update
    done
}

# Perform health check on all containers
health_check() {
    log "Performing health check on all containers..."

    local containers=$(podman ps -q)
    if [[ -z "$containers" ]]; then
        log "No running containers found"
        return 0
    fi

    local healthy_count=0
    local total_count=0

    for container_id in $containers; do
        ((total_count++))
        local health_status=$(podman inspect "$container_id" --format '{{.State.Health.Status}}' 2>/dev/null || echo "unknown")

        if [[ "$health_status" == "healthy" ]]; then
            ((healthy_count++))
            log "Container $container_id: HEALTHY"
        elif [[ "$health_status" == "unhealthy" ]]; then
            log "Container $container_id: UNHEALTHY"
        else
            log "Container $container_id: STATUS=$health_status"
        fi
    done

    log "Health check complete. Healthy: $healthy_count/$total_count"
}

# Main function
main() {
    local command="${1:-}"

    if [[ $# -eq 0 ]] || [[ "$command" == "-h" ]] || [[ "$command" == "--help" ]]; then
        print_help
        exit 0
    fi

    check_podman_installed

    case "$command" in
        list)
            list_containers
            ;;
        status)
            show_container_status "$2"
            ;;
        start)
            start_container "$2"
            ;;
        stop)
            stop_container "$2"
            ;;
        restart)
            restart_container "$2"
            ;;
        logs)
            show_logs "$2"
            ;;
        monitor)
            monitor_containers
            ;;
        health-check)
            health_check
            ;;
        *)
            log "ERROR: Unknown command '$command'"
            print_help
            exit 1
            ;;
    esac
}

# Execute main function with all arguments
main "$@"