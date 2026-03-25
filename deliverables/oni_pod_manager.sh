#!/bin/bash

# Oni Pod Manager - Secure Container Runtime Management
# Implements core functionality as specified in the design document

set -euo pipefail

# Default configuration
ONI_POD_CONFIG_DIR="${HOME}/.config/oni-pod"
ONI_POD_LOG_DIR="${HOME}/.local/share/oni-pod/logs"
ONI_POD_STATE_DIR="${HOME}/.local/share/oni-pod/state"

# Ensure directories exist
mkdir -p "$ONI_POD_CONFIG_DIR" "$ONI_POD_LOG_DIR" "$ONI_POD_STATE_DIR"

# Logging function
log_message() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "${ONI_POD_LOG_DIR}/oni-pod.log"
}

# Initialize Oni Pod
oni_pod_init() {
    log_message "INFO" "Initializing Oni Pod runtime environment"

    # Verify Podman is available
    if ! command -v podman &> /dev/null; then
        log_message "ERROR" "Podman is not installed or not in PATH"
        exit 1
    fi

    log_message "INFO" "Podman found: $(podman --version)"

    # Verify Podman connection
    podman info > /dev/null 2>&1 || {
        log_message "ERROR" "Cannot connect to Podman daemon/service"
        exit 1
    }

    log_message "INFO" "Oni Pod initialization completed successfully"
}

# List all containers
oni_pod_list() {
    log_message "INFO" "Listing all containers"

    echo "CONTAINER ID\tIMAGE\tCOMMAND\tCREATED\tSTATUS\tPORTS\tNAMES"
    podman ps -a --format "table {{.ID}}\t{{.Image}}\t{{.Command}}\t{{.CreatedAt}}\t{{.Status}}\t{{.Ports}}\t{{.Names}}"
}

# Get container status
oni_pod_status() {
    local container_name="$1"
    if [[ -z "$container_name" ]]; then
        log_message "ERROR" "Container name is required"
        echo "Usage: oni-pod status <container_name_or_id>"
        return 1
    fi

    log_message "INFO" "Checking status for container: $container_name"

    local status=$(podman inspect --format '{{.State.Status}}' "$container_name" 2>/dev/null || echo "not_found")

    if [[ "$status" == "not_found" ]]; then
        log_message "ERROR" "Container '$container_name' not found"
        return 1
    fi

    echo "Container: $container_name"
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
' "$container_name"
}

# Start a container
oni_pod_start() {
    local container_name="$1"
    if [[ -z "$container_name" ]]; then
        log_message "ERROR" "Container name is required"
        echo "Usage: oni-pod start <container_name_or_id>"
        return 1
    fi

    log_message "INFO" "Starting container: $container_name"

    if podman start "$container_name"; then
        log_message "INFO" "Container '$container_name' started successfully"
        return 0
    else
        log_message "ERROR" "Failed to start container '$container_name'"
        return 1
    fi
}

# Stop a container
oni_pod_stop() {
    local container_name="$1"
    if [[ -z "$container_name" ]]; then
        log_message "ERROR" "Container name is required"
        echo "Usage: oni-pod stop <container_name_or_id>"
        return 1
    fi

    log_message "INFO" "Stopping container: $container_name"

    if podman stop "$container_name"; then
        log_message "INFO" "Container '$container_name' stopped successfully"
        return 0
    else
        log_message "ERROR" "Failed to stop container '$container_name'"
        return 1
    fi
}

# Restart a container
oni_pod_restart() {
    local container_name="$1"
    if [[ -z "$container_name" ]]; then
        log_message "ERROR" "Container name is required"
        echo "Usage: oni-pod restart <container_name_or_id>"
        return 1
    fi

    log_message "INFO" "Restarting container: $container_name"

    if podman restart "$container_name"; then
        log_message "INFO" "Container '$container_name' restarted successfully"
        return 0
    else
        log_message "ERROR" "Failed to restart container '$container_name'"
        return 1
    fi
}

# Show container logs
oni_pod_logs() {
    local container_name="$1"
    local follow="${2:-false}"

    if [[ -z "$container_name" ]]; then
        log_message "ERROR" "Container name is required"
        echo "Usage: oni-pod logs <container_name_or_id> [follow]"
        return 1
    fi

    log_message "INFO" "Fetching logs for container: $container_name"

    if [[ "$follow" == "follow" ]]; then
        podman logs -f "$container_name"
    else
        podman logs "$container_name"
    fi
}

# Monitor containers continuously
oni_pod_monitor() {
    log_message "INFO" "Starting container monitoring"

    echo "Monitoring containers (Press Ctrl+C to stop)..."
    podman stats --all
}

# Perform health check on container
oni_pod_health_check() {
    local container_name="$1"
    if [[ -z "$container_name" ]]; then
        log_message "ERROR" "Container name is required"
        echo "Usage: oni-pod health-check <container_name_or_id>"
        return 1
    fi

    log_message "INFO" "Performing health check for container: $container_name"

    # Check container status
    local status=$(podman inspect --format '{{.State.Status}}' "$container_name" 2>/dev/null || echo "not_found")

    if [[ "$status" == "not_found" ]]; then
        log_message "ERROR" "Container '$container_name' not found"
        return 1
    fi

    # Check if container is running
    if [[ "$status" != "running" ]]; then
        log_message "WARNING" "Container '$container_name' is not running (status: $status)"
        return 1
    fi

    # Check health status if defined in container
    local health_status=$(podman inspect --format '{{.State.Health.Status}}' "$container_name" 2>/dev/null || echo "none")

    if [[ "$health_status" == "none" ]]; then
        log_message "INFO" "Container '$container_name' does not have healthcheck defined"
        echo "Container: $container_name"
        echo "Status: $status"
        echo "Health: Health check not configured in image"
        return 0
    else
        echo "Container: $container_name"
        echo "Status: $status"
        echo "Health: $health_status"

        if [[ "$health_status" == "healthy" ]]; then
            log_message "INFO" "Container '$container_name' is healthy"
            return 0
        else
            log_message "WARNING" "Container '$container_name' health status: $health_status"
            return 1
        fi
    fi
}

# Resource usage monitoring
oni_pod_resources() {
    log_message "INFO" "Checking resource usage for all containers"

    podman stats --no-stream
}

# Security scan placeholder function
oni_pod_security_scan() {
    local container_name="$1"
    log_message "INFO" "Performing security scan for container: ${container_name:-all}"

    # This is a placeholder - in a real implementation, this would connect to
    # a security scanning service like Trivy, Clair, or similar
    if [[ -n "$container_name" ]]; then
        # Get image from container
        local image=$(podman inspect --format '{{.Config.Image}}' "$container_name" 2>/dev/null || echo "")
        if [[ -n "$image" ]]; then
            echo "Would scan image '$image' for security vulnerabilities"
            log_message "INFO" "Security scan requested for image: $image"
        else
            log_message "ERROR" "Could not determine image for container: $container_name"
            return 1
        fi
    else
        # Scan all running containers
        local containers=$(podman ps --format "{{.ID}}" 2>/dev/null)
        if [[ -n "$containers" ]]; then
            while IFS= read -r container; do
                local image=$(podman inspect --format '{{.Config.Image}}' "$container" 2>/dev/null || echo "")
                if [[ -n "$image" ]]; then
                    echo "Would scan image '$image' for security vulnerabilities"
                    log_message "INFO" "Security scan requested for image: $image"
                fi
            done <<< "$containers"
        fi
    fi
}

# Create a new container with security defaults
oni_pod_create() {
    local image="$1"
    local name="$2"
    shift 2
    local extra_args="$*"

    if [[ -z "$image" ]] || [[ -z "$name" ]]; then
        log_message "ERROR" "Image and name are required for container creation"
        echo "Usage: oni-pod create <image> <name> [extra_args...]"
        return 1
    fi

    log_message "INFO" "Creating secure container: $name from image: $image"

    # Run podman with security defaults
    # These flags implement security best practices from the specification:
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

    log_message "DEBUG" "Executing: $cmd"

    eval $cmd
    if [[ $? -eq 0 ]]; then
        log_message "INFO" "Container '$name' created successfully"
        return 0
    else
        log_message "ERROR" "Failed to create container '$name'"
        return 1
    fi
}

# Main command router
main() {
    local command="$1"
    shift

    case "$command" in
        init)
            oni_pod_init
            ;;
        list)
            oni_pod_list
            ;;
        status)
            oni_pod_status "$@"
            ;;
        start)
            oni_pod_start "$@"
            ;;
        stop)
            oni_pod_stop "$@"
            ;;
        restart)
            oni_pod_restart "$@"
            ;;
        logs)
            oni_pod_logs "$@"
            ;;
        monitor)
            oni_pod_monitor
            ;;
        health-check)
            oni_pod_health_check "$@"
            ;;
        resources)
            oni_pod_resources
            ;;
        security-scan)
            oni_pod_security_scan "$@"
            ;;
        create)
            oni_pod_create "$@"
            ;;
        *)
            echo "Oni Pod - Secure Container Runtime Management"
            echo ""
            echo "Usage: $0 <command> [options]"
            echo ""
            echo "Available commands:"
            echo "  init          Initialize Oni Pod environment"
            echo "  list          List all containers"
            echo "  status NAME   Get status of specific container"
            echo "  start NAME    Start a container"
            echo "  stop NAME     Stop a container"
            echo "  restart NAME  Restart a container"
            echo "  logs NAME     Show container logs"
            echo "  logs NAME follow  Follow container logs"
            echo "  monitor       Monitor all containers"
            echo "  health-check NAME  Check health of container"
            echo "  resources     Show resource usage of containers"
            echo "  security-scan [NAME]  Scan container(s) for security issues"
            echo "  create IMAGE NAME [args...]  Create a new secure container"
            echo ""
            echo "Example: $0 list"
            echo "Example: $0 status my-container"
            echo "Example: $0 create nginx my-nginx-container -p 8080:80"
            return 1
            ;;
    esac
}

# Call main with all arguments
main "$@"