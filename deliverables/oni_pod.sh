#!/bin/bash

# Oni Pod - Main Entry Point
# Orchestrates all Oni Pod functionality

set -euo pipefail

# Determine script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Import configuration
CONFIG_FILE="${HOME}/.config/oni-pod/config.yaml"

# Default settings
DEFAULT_MONITOR_INTERVAL=30
DEFAULT_HEALTH_TIMEOUT=30

# Logging setup
LOG_DIR="${HOME}/.local/share/oni-pod/logs"
mkdir -p "$LOG_DIR"

# Log function
log_message() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "${LOG_DIR}/oni-pod-main.log"
}

# Initialize Oni Pod environment
initialize_environment() {
    log_message "INFO" "Initializing Oni Pod environment"

    # Check if Podman is available
    if ! command -v podman &> /dev/null; then
        log_message "ERROR" "Podman is not installed or not in PATH"
        echo "Error: Podman is not installed or not in PATH"
        exit 1
    fi

    # Run security validation
    log_message "INFO" "Running security validation"
    bash "$SCRIPT_DIR/oni_pod_security_layer.sh" validate-config

    # Initialize security policy
    log_message "INFO" "Initializing security policy"
    bash "$SCRIPT_DIR/oni_pod_security_layer.sh" init-policy

    log_message "INFO" "Environment initialization completed"
    echo "Oni Pod environment initialized successfully"
}

# Run a quick system check
system_check() {
    log_message "INFO" "Running system check"

    echo "Oni Pod System Check"
    echo "==================="

    # Check Podman version
    echo "Podman version: $(podman --version)"

    # Check if Podman is working
    echo "Podman connection: $(podman info > /dev/null 2>&1 && echo 'OK' || echo 'FAILED')"

    # Check number of containers
    local container_count=$(podman ps -a -q | wc -l)
    echo "Total containers: $container_count"

    # Check running containers
    local running_count=$(podman ps -q | wc -l)
    echo "Running containers: $running_count"

    # Check Oni Pod logs directory
    echo "Logs directory: $LOG_DIR ($(if [[ -d "$LOG_DIR" ]]; then echo "exists"; else echo "missing"; fi))"

    # Run security validation
    echo "Security validation:"
    bash "$SCRIPT_DIR/oni_pod_security_layer.sh" validate-config 2>&1 | sed 's/^/  /'
}

# Execute the manager functionality
execute_manager() {
    bash "$SCRIPT_DIR/oni_pod_manager.sh" "$@"
}

# Execute monitoring functionality
execute_monitoring() {
    bash "$SCRIPT_DIR/oni_pod_monitoring.sh" "$@"
}

# Execute systemd functionality
execute_systemd() {
    bash "$SCRIPT_DIR/oni_pod_systemd_manager.sh" "$@"
}

# Execute security functionality
execute_security() {
    bash "$SCRIPT_DIR/oni_pod_security_layer.sh" "$@"
}

# Show status dashboard
show_dashboard() {
    log_message "INFO" "Showing Oni Pod dashboard"

    echo "==========================================="
    echo "           ONI POD DASHBOARD              "
    echo "==========================================="
    echo ""

    # System status
    echo ".SYSTEM STATUS:"
    echo "  Podman: $(if command -v podman > /dev/null; then echo "installed ($(podman --version))"; else echo "not installed"; fi)"
    echo "  Podman connection: $(if podman info > /dev/null 2>&1; then echo "active"; else echo "inactive"; fi)"
    echo ""

    # Container statistics
    echo ".CONTAINER STATS:"
    local all_count=$(podman ps -a -q | wc -l)
    local running_count=$(podman ps -q | wc -l)
    local stopped_count=$((all_count - running_count))
    echo "  Total: $all_count"
    echo "  Running: $running_count"
    echo "  Stopped: $stopped_count"
    echo ""

    # Security status
    echo ".SECURITY STATUS:"
    if command -v getenforce > /dev/null 2>&1; then
        local selinux_status=$(getenforce 2>/dev/null || echo "disabled")
        echo "  SELinux: $selinux_status"
    else
        echo "  SELinux: not available"
    fi
    echo ""

    # Recent logs
    echo ".RECENT LOGS:"
    if [[ -f "${LOG_DIR}/oni-pod.log" ]]; then
        tail -n 5 "${LOG_DIR}/oni-pod.log" | sed 's/^/  /'
    else
        echo "  No recent logs available"
    fi
    echo ""

    echo "==========================================="
}

# Create a sample container with security defaults
create_sample_container() {
    local image="${1:-alpine}"
    local name="${2:-oni-sample-$(date +%s)}"

    log_message "INFO" "Creating sample container: $name with image: $image"

    echo "Creating sample container '$name' with image '$image'..."
    echo "Using security defaults as specified in Oni Pod design..."

    # Use the manager to create the container with security defaults
    bash "$SCRIPT_DIR/oni_pod_manager.sh" create "$image" "$name" sleep 3600

    if [[ $? -eq 0 ]]; then
        echo "Sample container created successfully: $name"

        # Perform security check on the new container
        echo "Performing security assessment..."
        bash "$SCRIPT_DIR/oni_pod_security_layer.sh" check-container "$name"

        # Show container status
        echo "Container status:"
        bash "$SCRIPT_DIR/oni_pod_manager.sh" status "$name"
    else
        echo "Failed to create sample container"
        return 1
    fi
}

# Main function
main() {
    local primary_command="$1"
    shift

    case "$primary_command" in
        init)
            initialize_environment
            ;;
        check)
            system_check
            ;;
        dashboard)
            show_dashboard
            ;;
        create-sample)
            create_sample_container "$@"
            ;;
        run-manager|--manager)
            execute_manager "$@"
            ;;
        run-monitoring|--monitoring)
            execute_monitoring "$@"
            ;;
        run-systemd|--systemd)
            execute_systemd "$@"
            ;;
        run-security|--security)
            execute_security "$@"
            ;;
        *)
            echo "Oni Pod - Secure Container Runtime"
            echo ""
            echo "Usage: $0 <command> [options]"
            echo ""
            echo "Core Commands:"
            echo "  init                    Initialize Oni Pod environment"
            echo "  check                   Run system check"
            echo "  dashboard               Show Oni Pod status dashboard"
            echo "  create-sample [IMAGE] [NAME]  Create a sample secure container"
            echo ""
            echo "Module Commands:"
            echo "  run-manager [args...]   Run container management functions"
            echo "  run-monitoring [args...] Run monitoring and logging functions"
            echo "  run-systemd [args...]   Run systemd integration functions"
            echo "  run-security [args...]  Run security layer functions"
            echo ""
            echo "Direct Access (for advanced users):"
            echo "  --manager [args...]     Direct access to manager script"
            echo "  --monitoring [args...]  Direct access to monitoring script"
            echo "  --systemd [args...]     Direct access to systemd script"
            echo "  --security [args...]    Direct access to security script"
            echo ""
            echo "Examples:"
            echo "  $0 init                           # Initialize Oni Pod"
            echo "  $0 check                          # System check"
            echo "  $0 dashboard                      # Show status dashboard"
            echo "  $0 create-sample nginx my-nginx   # Create sample container"
            echo "  $0 run-manager list               # List all containers"
            echo "  $0 run-monitoring health-check my-container  # Health check"
            return 1
            ;;
    esac
}

main "$@"