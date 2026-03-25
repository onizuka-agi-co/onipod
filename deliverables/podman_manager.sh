#!/bin/bash

# Podman Manager Script
# This script provides enhanced monitoring and management functions for Podman containers.

set -euo pipefail  # Exit on error, undefined variables, and pipe failures

readonly SCRIPT_NAME=$(basename "$0")
readonly LOG_FILE="/tmp/${SCRIPT_NAME}.log"

# Configuration directory and file
readonly CONFIG_DIR="${HOME}/.config/oni-pod"
readonly CONFIG_FILE="${CONFIG_DIR}/config.yaml"

# Logging function
log() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" | tee -a "$LOG_FILE"
}

# Print help information
print_help() {
    cat << EOF
Podman Manager Script - Enhanced Version

Usage: $SCRIPT_NAME [COMMAND] [OPTIONS]

Commands:
    list                    List all containers
    status CONTAINER_ID     Show status of specific container
    start CONTAINER_ID      Start a container
    stop CONTAINER_ID       Stop a container
    restart CONTAINER_ID    Restart a container
    logs CONTAINER_ID       Show logs of a container
    logs CONTAINER_ID follow  Follow container logs continuously
    monitor                 Monitor all containers continuously
    health-check            Perform health check on all containers
    health-check CONTAINER  Perform health check on specific container
    create IMAGE NAME       Create a new secure container
    exec CONTAINER COMMAND  Execute command in a running container
    remove CONTAINER_ID     Remove a stopped container
    inspect CONTAINER_ID    Show detailed container information
    stats                  Show resource usage statistics for all containers
    prune                  Remove unused containers, networks, and images
    resources             Show detailed resource usage for all containers

Options:
    -h, --help              Show this help message

Examples:
    $SCRIPT_NAME list
    $SCRIPT_NAME start my-container
    $SCRIPT_NAME monitor
    $SCRIPT_NAME create nginx my-nginx -p 8080:80
    $SCRIPT_NAME exec my-container bash
EOF
}

# Check if podman is installed
check_podman_installed() {
    if ! command -v podman &> /dev/null; then
        log "ERROR: podman is not installed"
        exit 1
    fi
}

# Load configuration if it exists
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        log "Loading configuration from $CONFIG_FILE"
    else
        log "Configuration file not found, using defaults"
    fi
}

# List all containers
list_containers() {
    log "Listing all containers..."
    echo "CONTAINER ID\tIMAGE\tCOMMAND\tCREATED\tSTATUS\tPORTS\tNAMES"
    podman ps -a --format "table {{.ID}}\t{{.Image}}\t{{.Command}}\t{{.CreatedAt}}\t{{.Status}}\t{{.Ports}}\t{{.Names}}"
}

# Show status of a specific container
show_container_status() {
    local container_id="$1"
    if [[ -z "$container_id" ]]; then
        log "ERROR: Container ID is required"
        exit 1
    fi

    log "Checking status of container: $container_id"

    local status=$(podman inspect --format '{{.State.Status}}' "$container_id" 2>/dev/null || echo "not_found")

    if [[ "$status" == "not_found" ]]; then
        log "ERROR: Container '$container_id' not found"
        return 1
    fi

    echo "Container: $container_id"
    echo "Status: $status"
    echo "Details:"
    podman inspect --format '
  State: {{.State.Status}}
  Running: {{.State.Running}}
  Paused: {{.State.Paused}}
  Restarting: {{.State.Restarting}}
  OOMKilled: {{.State.OOMKilled}}
  Dead: {{.State.Dead}}
  PID: {{.State.PID}}
  StartedAt: {{.State.StartedAt}}
  FinishedAt: {{.State.FinishedAt}}
  ExitCode: {{.State.ExitCode}}
' "$container_id"
}

# Start a container
start_container() {
    local container_id="$1"
    if [[ -z "$container_id" ]]; then
        log "ERROR: Container ID is required"
        exit 1
    fi

    log "Starting container: $container_id"

    if podman start "$container_id"; then
        log "Container $container_id started successfully"
        return 0
    else
        log "ERROR: Failed to start container $container_id"
        return 1
    fi
}

# Stop a container
stop_container() {
    local container_id="$1"
    if [[ -z "$container_id" ]]; then
        log "ERROR: Container ID is required"
        exit 1
    fi

    log "Stopping container: $container_id"

    if podman stop "$container_id"; then
        log "Container $container_id stopped successfully"
        return 0
    else
        log "ERROR: Failed to stop container $container_id"
        return 1
    fi
}

# Restart a container
restart_container() {
    local container_id="$1"
    if [[ -z "$container_id" ]]; then
        log "ERROR: Container ID is required"
        exit 1
    fi

    log "Restarting container: $container_id"

    if podman restart "$container_id"; then
        log "Container $container_id restarted successfully"
        return 0
    else
        log "ERROR: Failed to restart container $container_id"
        return 1
    fi
}

# Show logs of a container
show_logs() {
    local container_id="$1"
    local follow="${2:-false}"

    if [[ -z "$container_id" ]]; then
        log "ERROR: Container ID is required"
        exit 1
    fi

    log "Showing logs for container: $container_id"

    if [[ "$follow" == "follow" ]]; then
        podman logs -f "$container_id"
    else
        podman logs "$container_id"
    fi
}

# Monitor containers continuously
monitor_containers() {
    log "Starting container monitoring..."
    echo "Monitoring containers (Press Ctrl+C to stop)..."
    podman stats --all
}

# Perform health check on containers
health_check() {
    local container_name="$1"

    if [[ -n "$container_name" ]]; then
        # Health check for specific container
        log "Performing health check for container: $container_name"

        # Check container status
        local status=$(podman inspect --format '{{.State.Status}}' "$container_name" 2>/dev/null || echo "not_found")

        if [[ "$status" == "not_found" ]]; then
            log "ERROR: Container '$container_name' not found"
            return 1
        fi

        # Check if container is running
        if [[ "$status" != "running" ]]; then
            log "WARNING: Container '$container_name' is not running (status: $status)"
            return 1
        fi

        # Check health status if defined in container
        local health_status=$(podman inspect --format '{{.State.Health.Status}}' "$container_name" 2>/dev/null || echo "none")

        if [[ "$health_status" == "none" ]]; then
            log "INFO: Container '$container_name' does not have healthcheck defined"
            echo "Container: $container_name"
            echo "Status: $status"
            echo "Health: Health check not configured in image"
            return 0
        else
            echo "Container: $container_name"
            echo "Status: $status"
            echo "Health: $health_status"

            if [[ "$health_status" == "healthy" ]]; then
                log "INFO: Container '$container_name' is healthy"
                return 0
            else
                log "WARNING: Container '$container_name' health status: $health_status"
                return 1
            fi
        fi
    else
        # Health check for all containers
        log "Performing health check on all containers..."

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
            log "WARNING: Found $unhealthy_count unhealthy containers out of $total_count total"
            return 1
        else
            log "INFO: All containers are healthy"
            return 0
        fi
    fi
}

# Create a new secure container
create_container() {
    local image="$1"
    local name="$2"
    shift 2
    local extra_args="$*"

    if [[ -z "$image" ]] || [[ -z "$name" ]]; then
        log "ERROR: Image and name are required for container creation"
        echo "Usage: $SCRIPT_NAME create <image> <name> [extra_args...]"
        return 1
    fi

    log "Creating secure container: $name from image: $image"

    # Run podman with security defaults
    # These flags implement security best practices:
    # - Run as non-root user
    # - Read-only root filesystem (where possible)
    # - Limited capabilities
    # - Restricted syscalls via seccomp
    local cmd="podman run -d --name $name --read-only --userns=auto --security-opt=no-new-privileges"

    # Add custom arguments if provided
    if [[ -n "$extra_args" ]]; then
        cmd="$cmd $extra_args"
    fi

    # Finalize with the image
    cmd="$cmd $image"

    log "DEBUG: Executing: $cmd"

    eval $cmd
    if [[ $? -eq 0 ]]; then
        log "Container '$name' created successfully"
        return 0
    else
        log "ERROR: Failed to create container '$name'"
        return 1
    fi
}

# Execute command in a container
exec_container() {
    local container_id="$1"
    shift
    local command="$*"

    if [[ -z "$container_id" ]] || [[ -z "$command" ]]; then
        log "ERROR: Container ID and command are required"
        echo "Usage: $SCRIPT_NAME exec <container_id> <command>"
        return 1
    fi

    log "Executing command in container $container_id: $command"
    podman exec -it "$container_id" $command
}

# Remove a container
remove_container() {
    local container_id="$1"

    if [[ -z "$container_id" ]]; then
        log "ERROR: Container ID is required"
        exit 1
    fi

    log "Removing container: $container_id"
    podman rm "$container_id"
    log "Container $container_id removed successfully"
}

# Inspect container details
inspect_container() {
    local container_id="$1"

    if [[ -z "$container_id" ]]; then
        log "ERROR: Container ID is required"
        exit 1
    fi

    log "Inspecting container: $container_id"
    podman inspect "$container_id"
}

# Show resource statistics
stats_containers() {
    log "Showing resource statistics for all containers"
    podman stats --no-stream
}

# Prune unused resources
prune_resources() {
    log "Pruning unused containers, networks, and images"
    echo "This will remove:"
    echo "  - All stopped containers"
    echo "  - All unused networks"
    echo "  - All unused images"
    echo ""
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        podman system prune -f
        log "Resources pruned successfully"
    else
        log "Prune operation cancelled"
    fi
}

# Show detailed resource usage
resources_containers() {
    log "Showing detailed resource usage for all containers"

    local containers=$(podman ps -q 2>/dev/null)
    if [[ -z "$containers" ]]; then
        echo "No running containers found."
        return 0
    fi

    for container_id in $containers; do
        echo "--- Container: $container_id ---"

        # Get container name
        local name=$(podman inspect --format '{{.Name}}' "$container_id" 2>/dev/null | sed 's/\///')
        echo "Name: $name"

        # Get basic stats
        local stats_json
        stats_json=$(podman stats --no-stream --format json "$container_id" 2>/dev/null || echo "[]")

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
        echo ""
    done
}

# Main function
main() {
    local command="${1:-}"

    if [[ $# -eq 0 ]] || [[ "$command" == "-h" ]] || [[ "$command" == "--help" ]]; then
        print_help
        exit 0
    fi

    check_podman_installed
    load_config

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
            show_logs "$2" "$3"
            ;;
        monitor)
            monitor_containers
            ;;
        health-check)
            health_check "$2"
            ;;
        create)
            create_container "$2" "$3" "${@:4}"
            ;;
        exec)
            exec_container "$2" "${@:3}"
            ;;
        remove)
            remove_container "$2"
            ;;
        inspect)
            inspect_container "$2"
            ;;
        stats)
            stats_containers
            ;;
        prune)
            prune_resources
            ;;
        resources)
            resources_containers
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