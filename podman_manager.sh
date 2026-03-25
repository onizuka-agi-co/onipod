#!/bin/bash

# Podman Container Manager Script
# This script provides basic operations for Podman containers including:
# - Listing containers
# - Viewing logs
# - Starting, stopping, and removing containers
# - Monitoring container status

set -euo pipefail  # Exit on error, undefined variables, and pipe failures

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
    echo "  help                    Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 list"
    echo "  $0 logs mycontainer"
    echo "  $0 start mycontainer"
    echo "  $0 monitor"
    echo ""
}

# Function to check if podman is installed
check_podman() {
    if ! command -v podman &> /dev/null; then
        echo -e "${RED}Error: Podman is not installed or not in PATH${NC}" >&2
        exit 1
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

# Function to monitor container status continuously
monitor_containers() {
    echo -e "${BLUE}Monitoring container status (Press Ctrl+C to exit)...${NC}"

    # Print initial header
    printf "%-20s %-15s %-20s %-15s\n" "CONTAINER NAME" "STATUS" "IMAGE" "CREATED"
    echo "------------------------------------------------------------------------"

    while true; do
        # Clear the screen (optional - uncomment if desired)
        # clear

        # Get container info with current status
        podman ps -a --format "{{.Names}}|{{.Status}}|{{.Image}}|{{.CreatedAt}}" | while IFS='|' read -r name status image created; do
            # Color code based on status
            if [[ "$status" =~ ^Up ]]; then
                color=$GREEN
            elif [[ "$status" =~ Exited ]]; then
                color=$RED
            else
                color=$YELLOW
            fi

            printf "%-20s ${color}%-15s${NC} %-20s %-15s\n" "$name" "$status" "$image" "$created"
        done
        echo "------------------------------------------------------------------------"

        # Wait for 5 seconds before refreshing
        sleep 5
    done
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

    echo ""
    echo "Container Details:"
    podman inspect "$container_name" | jq -r '
        {
          "State": .[0].State.Status,
          "StartedAt": .[0].State.StartedAt,
          "FinishedAt": .[0].State.FinishedAt,
          "Health": .[0].State.Health?.Status // "N/A",
          "IPAddress": .[0].NetworkSettings.IPAddress,
          "Mounts": .[0].Mounts | length | tostring + " mount(s)",
          "EnvVarsCount": .[0].Config.Env | length | tostring + " variables"
        } | to_entries[] | "\(.key):\(.value)"'
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

# Main function
main() {
    check_podman

    local cmd="${1:-help}"

    case "$cmd" in
        "list")
            list_containers
            ;;
        "logs")
            show_logs "${2:-}"
            ;;
        "start")
            start_container "${2:-}"
            ;;
        "stop")
            stop_container "${2:-}"
            ;;
        "restart")
            restart_container "${2:-}"
            ;;
        "remove")
            remove_container "${2:-}"
            ;;
        "monitor")
            monitor_containers
            ;;
        "status")
            show_status "${2:-}"
            ;;
        "ps")
            show_running_containers
            ;;
        "stats")
            show_stats
            ;;
        "help"|"-h"|"--help")
            usage
            ;;
        *)
            echo -e "${RED}Error: Unknown command '$cmd'${NC}" >&2
            echo ""
            usage
            exit 1
            ;;
    esac
}

# Call main function with all arguments
main "$@"