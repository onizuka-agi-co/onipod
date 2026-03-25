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
    echo "  stats-detail [CPU_THRESHOLD] [MEM_THRESHOLD] [INTERVAL] [NETWORK_THRESHOLD] [DISK_THRESHOLD] Show detailed resource usage statistics with alert thresholds"
    echo "  resource-report [DURATION] [INTERVAL] Generate a resource usage report over time"
    echo "  security-scan CONTAINER_NAME [OUTPUT_FORMAT] [SEVERITY_FILTER] [LOG_FILE] [CONFIG_ANALYSIS] Perform security scan on a container image"
    echo "  batch-operation OPERATION REGEX_PATTERN [CONFIRM] Perform batch operation on multiple containers matching the pattern"
    echo "  help                    Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 list"
    echo "  $0 logs mycontainer"
    echo "  $0 start mycontainer"
    echo "  $0 monitor"
    echo "  $0 stats-detail         # Monitor with default thresholds (CPU: 80%, MEM: 90%)"
    echo "  $0 stats-detail 90 95   # Monitor with custom thresholds (CPU: 90%, MEM: 95%)"
    echo "  $0 stats-detail 90 95 3 100 50  # Monitor with custom thresholds including network (100MB) and disk (50MB)"
    echo "  $0 resource-report      # Generate report for 60s with 5s intervals"
    echo "  $0 resource-report 120 10  # Generate report for 120s with 10s intervals"
    echo "  $0 security-scan mycontainer  # Scan container image for vulnerabilities"
    echo "  $0 security-scan mycontainer json HIGH,CRITICAL,LOW my_scan.log true  # Scan with config analysis"
    echo "  $0 batch-operation stop '^web.*'  # Stop all containers whose names start with 'web'"
    echo "  $0 batch-operation stop '^web.*' confirm  # Stop with confirmation"
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

# Function to show detailed resource usage statistics with alert thresholds
show_detailed_stats() {
    local cpu_threshold=${1:-80}
    local mem_threshold=${2:-90}
    local interval=${3:-2}
    local network_threshold=${4:-""}  # Optional network usage threshold in MB
    local disk_threshold=${5:-""}     # Optional disk usage threshold in MB

    echo -e "${BLUE}Detailed container resource usage statistics (Ctrl+C to stop):${NC}"
    echo "Alert thresholds: CPU > ${cpu_threshold}%, Memory > ${mem_threshold}%"
    if [[ -n "$network_threshold" ]]; then
        echo "Network threshold: > ${network_threshold}MB"
    fi
    if [[ -n "$disk_threshold" ]]; then
        echo "Disk threshold: > ${disk_threshold}MB"
    fi
    echo ""

    # Check if podman stats supports the format we need
    if ! podman stats --no-stream --format "{{.Name}}\t{{.PID}}\t{{.CPU}}\t{{.MemUsage}}\t{{.Mem}}\t{{.NetIO}}\t{{.BlockIO}}" 2>/dev/null | head -1; then
        echo "No running containers or stats not available"
        return 1
    fi

    # Continuous monitoring
    trap 'echo -e "\n${YELLOW}Monitoring stopped.${NC}"; exit 0' INT TERM

    while true; do
        clear
        echo -e "${BLUE}Detailed container resource usage statistics (Ctrl+C to stop):${NC}"
        echo "Alert thresholds: CPU > ${cpu_threshold}%, Memory > ${mem_threshold}%"
        if [[ -n "$network_threshold" ]]; then
            echo "Network threshold: > ${network_threshold}MB"
        fi
        if [[ -n "$disk_threshold" ]]; then
            echo "Disk threshold: > ${disk_threshold}MB"
        fi
        echo ""

        # Print header
        printf "%-20s %-10s %-10s %-20s %-10s %-20s %-20s %s\n" "NAME" "PID" "CPU%" "MEM USAGE" "MEM %" "NET I/O" "BLOCK I/O" "STATUS"
        echo " --------------------------------------------------------------------------------------------------------------------"

        # Process each container's stats and check for threshold breaches
        podman stats --no-stream --format "{{.Name}}|{{.PID}}|{{.CPU}}|{{.MemUsage}}|{{.Mem}}|{{.NetIO}}|{{.BlockIO}}|{{.Status}}" 2>/dev/null | while IFS='|' read -r name pid cpu mem_usage mem netio blockio status; do
            # Skip the header row
            if [[ "$name" == "NAME" ]]; then
                continue
            fi

            # Extract numeric values for comparison
            cpu_num=$(echo "$cpu" | sed 's/%//' | sed 's/ *$//g')
            mem_percent=$(echo "$mem" | sed 's/%//' | sed 's/ *$//g')

            # Extract network and block IO numbers for comparison if thresholds are set
            net_rx_mb=$(echo "$netio" | awk -F'[ /]' '{print $1}' | sed 's/M$//')
            net_tx_mb=$(echo "$netio" | awk -F'[ /]' '{print $4}' | sed 's/M$//')

            # Extract block IO if available
            block_read_mb=$(echo "$blockio" | awk -F'[ /]' '{print $1}' | sed 's/M$//' 2>/dev/null || echo 0)
            block_write_mb=$(echo "$blockio" | awk -F'[ /]' '{print $4}' | sed 's/M$//' 2>/dev/null || echo 0)

            # Determine if alert thresholds are exceeded
            cpu_alert=""
            mem_alert=""
            net_alert=""
            disk_alert=""

            if (( $(echo "$cpu_num > $cpu_threshold" | bc -l 2>/dev/null || echo 0) )); then
                cpu_alert=" ${RED}[HIGH CPU!]${NC}"
            fi

            if (( $(echo "$mem_percent > $mem_threshold" | bc -l 2>/dev/null || echo 0) )); then
                mem_alert=" ${RED}[HIGH MEM!]${NC}"
            fi

            # Check network threshold if provided
            if [[ -n "$network_threshold" ]]; then
                total_net_mb=$(echo "$net_rx_mb + $net_tx_mb" | bc -l 2>/dev/null || echo 0)
                if (( $(echo "$total_net_mb > $network_threshold" | bc -l 2>/dev/null || echo 0) )); then
                    net_alert=" ${RED}[HIGH NET!]${NC}"
                fi
            fi

            # Check disk threshold if provided
            if [[ -n "$disk_threshold" ]]; then
                total_disk_mb=$(echo "$block_read_mb + $block_write_mb" | bc -l 2>/dev/null || echo 0)
                if (( $(echo "$total_disk_mb > $disk_threshold" | bc -l 2>/dev/null || echo 0) )); then
                    disk_alert=" ${RED}[HIGH DISK!]${NC}"
                fi
            fi

            # Set color based on alert status
            if [[ -n "$cpu_alert" ]] || [[ -n "$mem_alert" ]] || [[ -n "$net_alert" ]] || [[ -n "$disk_alert" ]]; then
                color="${RED}"
            else
                color="${GREEN}"
            fi

            # Format output with alert indicators
            printf "${color}%-20s${NC} %-10s %-10s %-20s %-10s %-20s %-20s %s%s%s%s%s\n" \
                "$name" "$pid" "$cpu" "$mem_usage" "$mem" "$netio" "$blockio" "$status" "$cpu_alert" "$mem_alert" "$net_alert" "$disk_alert"
        done

        # Show additional container-specific disk usage information
        echo ""
        echo -e "${BLUE}Additional Resource Information:${NC}"
        echo "Container Disk Usage (Top 10):"
        podman ps --format "{{.ID}}|{{.Names}}" | tail -n +2 | while IFS='|' read -r id name; do
            if [[ -n "$id" ]]; then
                # Get container rootfs size
                size_info=$(podman container inspect "$id" 2>/dev/null | jq -r '.[].SizeRootFs // empty' 2>/dev/null)
                if [[ -n "$size_info" && "$size_info" != "null" ]]; then
                    size_mb=$((size_info / 1024 / 1024))
                    printf "  %s (%s): %d MB\n" "$name" "$id" "$size_mb"
                fi
            fi
        done | head -10

        echo ""
        echo "Next update in ${interval}s... Press Ctrl+C to stop"

        sleep "$interval"
    done
}

# Function to monitor resource usage and generate reports
resource_monitor_report() {
    local report_duration=${1:-60}  # Duration in seconds to collect data
    local report_interval=${2:-5}   # Interval in seconds between measurements
    local report_file="resource_report_$(date +%Y%m%d_%H%M%S).txt"

    echo -e "${BLUE}Collecting resource usage data for ${report_duration}s...${NC}"

    # Initialize arrays to store data
    declare -A cpu_data
    declare -A mem_data
    declare -A container_names

    local collected_samples=0
    local total_samples=$((report_duration / report_interval))

    # Collect data over time
    for i in $(seq 1 $total_samples); do
        echo -e "${YELLOW}Collecting sample $i/$total_samples...${NC}"

        podman stats --no-stream --format "{{.Name}}|{{.CPU}}|{{.Mem}}" 2>/dev/null | while IFS='|' read -r name cpu mem; do
            if [[ "$name" != "NAME" && -n "$name" ]]; then
                # Store container name
                container_names["$name"]=1

                # Extract numeric values
                cpu_val=$(echo "$cpu" | sed 's/%//')
                mem_val=$(echo "$mem" | sed 's/%//')

                # Append to data arrays
                if [[ -n "${cpu_data[$name]+isset}" ]]; then
                    cpu_data["$name"]="${cpu_data[$name]},$cpu_val"
                    mem_data["$name"]="${mem_data[$name]},$mem_val"
                else
                    cpu_data["$name"]="$cpu_val"
                    mem_data["$name"]="$mem_val"
                fi
            fi
        done

        sleep "$report_interval"
        collected_samples=$((collected_samples + 1))
    done

    # Generate report
    echo -e "${GREEN}Generating resource usage report...${NC}"
    {
        echo "PODMAN RESOURCE USAGE REPORT"
        echo "Generated on: $(date)"
        echo "Duration: ${report_duration}s, Sample interval: ${report_interval}s"
        echo "==========================================="
        echo ""

        # For each container, calculate min/max/avg values
        for container in "${!container_names[@]}"; do
            echo "Container: $container"

            # Calculate CPU stats
            IFS=',' read -ra cpu_vals <<< "${cpu_data[$container]}"
            local cpu_sum=0
            local cpu_min=100
            local cpu_max=0
            for val in "${cpu_vals[@]}"; do
                if (( $(echo "$val > $cpu_max" | bc -l 2>/dev/null || echo 0) )); then cpu_max=$val; fi
                if (( $(echo "$val < $cpu_min" | bc -l 2>/dev/null || echo 0) )); then cpu_min=$val; fi
                cpu_sum=$(echo "$cpu_sum + $val" | bc -l 2>/dev/null || echo 0)
            done
            local cpu_avg=$(echo "$cpu_sum / ${#cpu_vals[@]}" | bc -l 2>/dev/null || echo 0)

            # Calculate Memory stats
            IFS=',' read -ra mem_vals <<< "${mem_data[$container]}"
            local mem_sum=0
            local mem_min=100
            local mem_max=0
            for val in "${mem_vals[@]}"; do
                if (( $(echo "$val > $mem_max" | bc -l 2>/dev/null || echo 0) )); then mem_max=$val; fi
                if (( $(echo "$val < $mem_min" | bc -l 2>/dev/null || echo 0) )); then mem_min=$val; fi
                mem_sum=$(echo "$mem_sum + $val" | bc -l 2>/dev/null || echo 0)
            done
            local mem_avg=$(echo "$mem_sum / ${#mem_vals[@]}" | bc -l 2>/dev/null || echo 0)

            printf "  CPU: Min=%.2f%%, Max=%.2f%%, Avg=%.2f%%\n" "$cpu_min" "$cpu_max" "$cpu_avg"
            printf "  Mem: Min=%.2f%%, Max=%.2f%%, Avg=%.2f%%\n" "$mem_min" "$mem_max" "$mem_avg"
            echo ""
        done
    } > "$report_file"

    echo -e "${GREEN}Report saved to: $report_file${NC}"
    echo ""
    echo -e "${BLUE}Summary:${NC}"
    cat "$report_file" | grep -E "(Container:|Avg=)" | grep -v "Min=" | grep -v "Max="
}

# Function to perform security scan on container images
security_scan() {
    local container_name="$1"
    local output_format="${2:-table}"  # table, json, or sarif
    local severity_filter="${3:-HIGH,CRITICAL}"  # LOW, MEDIUM, HIGH, CRITICAL
    local log_file="${4:-security_scan_results_$(date +%Y%m%d_%H%M%S).log}"
    local include_config_analysis="${5:-false}"  # Whether to include configuration analysis

    if [[ -z "$container_name" ]]; then
        echo -e "${RED}Error: Container name is required${NC}" >&2
        return 1
    fi

    echo -e "${BLUE}Performing security scan for container '$container_name'...${NC}"

    # Check if container exists
    if ! podman inspect "$container_name" &>/dev/null; then
        echo -e "${RED}Error: Container '$container_name' does not exist${NC}" >&2
        return 1
    fi

    # Get the image name from the container
    local image_name
    image_name=$(podman inspect "$container_name" --format '{{.Config.Image}}')

    if [[ -z "$image_name" ]]; then
        echo -e "${RED}Error: Could not determine image name for container '$container_name'${NC}" >&2
        return 1
    fi

    echo -e "${YELLOW}Scanning image: $image_name${NC}"

    # Check if trivy is available
    if command -v trivy &> /dev/null; then
        echo -e "${BLUE}Using Trivy for security scanning...${NC}"

        # Prepare trivy scan command with severity filter
        local trivy_cmd="trivy image --security-checks vuln,config -f $output_format --vuln-type os,library --severity $severity_filter \"$image_name\""

        # If configuration analysis is enabled, add the config scan
        if [[ "$include_config_analysis" == "true" ]]; then
            trivy_cmd="trivy image --security-checks vuln,config -f $output_format --vuln-type os,library --severity $severity_filter --scanners vuln,config \"$image_name\""
        fi

        # Execute the scan and save to log file
        if eval $trivy_cmd > "$log_file" 2>/dev/null; then
            echo -e "${GREEN}Security scan completed successfully. Results saved to $log_file${NC}"

            # Display filtered results highlighting important vulnerabilities
            echo -e "${BLUE}Scan Results:${NC}"

            # Display only the most critical information based on output format
            if [[ "$output_format" == "table" ]]; then
                # For table format, highlight critical sections
                cat "$log_file" | while IFS= read -r line; do
                    if [[ $line =~ CRITICAL|HIGH ]]; then
                        echo -e "${RED}$line${NC}"
                    elif [[ $line =~ MEDIUM ]]; then
                        echo -e "${YELLOW}$line${NC}"
                    elif [[ $line =~ SEVERITY|VULNERABILITY|TOTAL ]]; then
                        echo -e "${BLUE}$line${NC}"
                    else
                        echo "$line"
                    fi
                done
            elif [[ "$output_format" == "json" ]]; then
                # For JSON, pretty print and highlight issues
                if command -v jq &> /dev/null; then
                    cat "$log_file" | jq .
                else
                    cat "$log_file"
                fi
            else
                cat "$log_file"
            fi

            # Count vulnerabilities by severity
            local critical_count=$(grep -c "CRITICAL" "$log_file" 2>/dev/null || echo 0)
            local high_count=$(grep -c "HIGH" "$log_file" 2>/dev/null || echo 0)
            local medium_count=$(grep -c "MEDIUM" "$log_file" 2>/dev/null || echo 0)
            local low_count=$(grep -c "LOW" "$log_file" 2>/dev/null || echo 0)

            echo ""
            echo -e "${BLUE}Vulnerability Summary:${NC}"
            echo -e "${RED}CRITICAL: $critical_count${NC}"
            echo -e "${RED}HIGH: $high_count${NC}"
            echo -e "${YELLOW}MEDIUM: $medium_count${NC}"
            echo "LOW: $low_count"

            # Also analyze misconfigurations if config analysis was included
            if [[ "$include_config_analysis" == "true" ]]; then
                local misconfig_count=$(grep -i -c "misconfig\|configuration\|config_issue" "$log_file" 2>/dev/null || echo 0)
                echo -e "${YELLOW}CONFIG ISSUES: $misconfig_count${NC}"
            fi

            if [ "$critical_count" -gt 0 ] || [ "$high_count" -gt 0 ]; then
                echo -e "${RED}WARNING: Critical or High severity vulnerabilities detected!${NC}"
                return 1
            else
                echo -e "${GREEN}No critical or high severity vulnerabilities found.${NC}"
            fi
        else
            echo -e "${RED}Trivy scan failed for image '$image_name'${NC}" >&2
            return 1
        fi
    # Alternative: Check if podman has built-in security scanning capability
    elif podman image scan --help &>/dev/null; then
        echo -e "${BLUE}Using Podman's built-in security scanning...${NC}"

        # Podman scan might not be available in all versions, so we'll try to use it
        if podman image scan --format "$output_format" --severity "$severity_filter" "$image_name" > "$log_file" 2>&1; then
            echo -e "${GREEN}Security scan completed successfully. Results saved to $log_file${NC}"

            # Display results with color coding
            cat "$log_file" | while IFS= read -r line; do
                if [[ $line =~ CRITICAL|HIGH ]]; then
                    echo -e "${RED}$line${NC}"
                elif [[ $line =~ MEDIUM ]]; then
                    echo -e "${YELLOW}$line${NC}"
                else
                    echo "$line"
                fi
            done
        else
            echo -e "${RED}Podman security scan failed for image '$image_name'${NC}" >&2
            return 1
        fi
    else
        echo -e "${RED}Error: Neither Trivy nor Podman security scanning is available${NC}" >&2
        echo -e "${YELLOW}Install Trivy (https://aquasecurity.github.io/trivy/) for comprehensive security scanning capabilities${NC}" >&2
        return 1
    fi

    # Generate security recommendations based on findings
    generate_security_recommendations "$image_name" "$critical_count" "$high_count" "$medium_count" "$low_count"
}

# Function to generate security recommendations based on scan results
generate_security_recommendations() {
    local image_name="$1"
    local critical_count="$2"
    local high_count="$3"
    local medium_count="$4"
    local low_count="$5"

    echo ""
    echo -e "${BLUE}Security Recommendations:${NC}"

    if [ "$critical_count" -gt 0 ] || [ "$high_count" -gt 0 ]; then
        echo -e "${RED}- CRITICAL/HIGH vulnerabilities detected: Update to latest patched version${NC}"
        echo -e "${RED}- Consider using an alternative image with fewer vulnerabilities${NC}"
    fi

    if [ "$medium_count" -gt 0 ]; then
        echo -e "${YELLOW}- Medium vulnerabilities: Review and patch as soon as possible${NC}"
    fi

    if [ "$low_count" -gt 0 ]; then
        echo -e "${BLUE}- Low vulnerabilities: Monitor for future updates${NC}"
    fi

    echo "- Consider implementing a regular security scanning schedule"
    echo "- Verify image signatures and source authenticity"
    echo "- Use minimal base images to reduce attack surface"
}

# Function to perform batch operations on multiple containers
batch_operation() {
    local operation="$1"
    local pattern="$2"
    local confirmation_flag="${3:-false}"  # Optional flag for confirmation before executing operations

    if [[ -z "$operation" ]] || [[ -z "$pattern" ]]; then
        echo -e "${RED}Error: Both operation and pattern are required${NC}" >&2
        echo "Usage: $0 batch-operation [start|stop|restart|remove|pause|unpause] REGEX_PATTERN [confirm]"
        return 1
    fi

    # Validate operation
    if [[ ! "$operation" =~ ^(start|stop|restart|remove|pause|unpause)$ ]]; then
        echo -e "${RED}Error: Invalid operation '$operation'. Valid operations: start, stop, restart, remove, pause, unpause${NC}" >&2
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
    local container_list=()
    while IFS= read -r container; do
        if [[ -n "$container" ]]; then
            container_list+=("$container")
            echo "  - $container"
        fi
    done <<< "$matched_containers"

    # If confirmation flag is set, ask for confirmation before proceeding
    if [[ "$confirmation_flag" == "confirm" ]]; then
        echo ""
        echo -e "${YELLOW}Do you want to proceed with $operation operation on ${#container_list[@]} containers? (yes/no):${NC}"
        read -r confirm
        if [[ ! "$confirm" =~ ^[Yy][Ee][Ss]$ ]]; then
            echo -e "${YELLOW}Operation cancelled by user.${NC}"
            return 0
        fi
    fi

    echo ""
    echo -e "${BLUE}Executing batch operation '$operation'...${NC}"

    # Additional function for pause/unpause since these aren't defined yet
    pause_container() {
        local container_name="$1"
        if [[ -z "$container_name" ]]; then
            echo -e "${RED}Error: Container name is required${NC}" >&2
            return 1
        fi

        echo -e "${YELLOW}Pausing container '$container_name'...${NC}"
        if podman pause "$container_name"; then
            echo -e "${GREEN}Container '$container_name' paused successfully${NC}"
        else
            echo -e "${RED}Failed to pause container '$container_name'${NC}" >&2
            return 1
        fi
    }

    unpause_container() {
        local container_name="$1"
        if [[ -z "$container_name" ]]; then
            echo -e "${RED}Error: Container name is required${NC}" >&2
            return 1
        fi

        echo -e "${YELLOW}Unpausing container '$container_name'...${NC}"
        if podman unpause "$container_name"; then
            echo -e "${GREEN}Container '$container_name' unpaused successfully${NC}"
        else
            echo -e "${RED}Failed to unpause container '$container_name'${NC}" >&2
            return 1
        fi
    }

    # Temporary files to track results
    local temp_successful=$(mktemp)
    local temp_failed=$(mktemp)

    # Process each matched container
    for container in "${container_list[@]}"; do
        if [[ -n "$container" ]]; then
            echo -e "${YELLOW}Processing container '$container'...${NC}"

            case "$operation" in
                "start")
                    if start_container "$container"; then
                        echo "$container" >> "$temp_successful"
                        echo -e "${GREEN}Successfully started container '$container'${NC}"
                    else
                        echo "$container" >> "$temp_failed"
                        echo -e "${RED}Failed to start container '$container'${NC}"
                    fi
                    ;;
                "stop")
                    if stop_container "$container"; then
                        echo "$container" >> "$temp_successful"
                        echo -e "${GREEN}Successfully stopped container '$container'${NC}"
                    else
                        echo "$container" >> "$temp_failed"
                        echo -e "${RED}Failed to stop container '$container'${NC}"
                    fi
                    ;;
                "restart")
                    if restart_container "$container"; then
                        echo "$container" >> "$temp_successful"
                        echo -e "${GREEN}Successfully restarted container '$container'${NC}"
                    else
                        echo "$container" >> "$temp_failed"
                        echo -e "${RED}Failed to restart container '$container'${NC}"
                    fi
                    ;;
                "remove")
                    if remove_container "$container"; then
                        echo "$container" >> "$temp_successful"
                        echo -e "${GREEN}Successfully removed container '$container'${NC}"
                    else
                        echo "$container" >> "$temp_failed"
                        echo -e "${RED}Failed to remove container '$container'${NC}"
                    fi
                    ;;
                "pause")
                    if pause_container "$container"; then
                        echo "$container" >> "$temp_successful"
                        echo -e "${GREEN}Successfully paused container '$container'${NC}"
                    else
                        echo "$container" >> "$temp_failed"
                        echo -e "${RED}Failed to pause container '$container'${NC}"
                    fi
                    ;;
                "unpause")
                    if unpause_container "$container"; then
                        echo "$container" >> "$temp_successful"
                        echo -e "${GREEN}Successfully unpaused container '$container'${NC}"
                    else
                        echo "$container" >> "$temp_failed"
                        echo -e "${RED}Failed to unpause container '$container'${NC}"
                    fi
                    ;;
            esac
        fi
    done

    # Read results from temp files
    local successful_operations=()
    local failed_operations=()

    while IFS= read -r container; do
        if [[ -n "$container" ]]; then
            successful_operations+=("$container")
        fi
    done < "$temp_successful"

    while IFS= read -r container; do
        if [[ -n "$container" ]]; then
            failed_operations+=("$container")
        fi
    done < "$temp_failed"

    # Clean up temp files
    rm -f "$temp_successful" "$temp_failed"

    # Display summary
    echo ""
    echo -e "${BLUE}Batch operation summary:${NC}"
    echo -e "Operation: ${YELLOW}$operation${NC}"
    echo -e "Pattern: ${YELLOW}$pattern${NC}"
    echo -e "Confirmation used: ${YELLOW}$confirmation_flag${NC}"
    echo -e "Total containers processed: ${#successful_operations[@] + #failed_operations[@]}"
    echo -e "Successful: ${GREEN}${#successful_operations[@]}${NC}"
    echo -e "Failed: ${RED}${#failed_operations[@]}${NC}"

    if [[ ${#successful_operations[@]} -gt 0 ]]; then
        echo -e "${GREEN}Successful operations:${NC}"
        for container in "${successful_operations[@]}"; do
            echo "  - $container"
        done
    fi

    if [[ ${#failed_operations[@]} -gt 0 ]]; then
        echo -e "${RED}Failed operations:${NC}"
        for container in "${failed_operations[@]}"; do
            echo "  - $container"
        done
        return 1
    fi
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
        "stats-detail")
            show_detailed_stats "${2:-80}" "${3:-90}" "${4:-2}" "${5:-""}" "${6:-""}"
            ;;
        "resource-report")
            resource_monitor_report "${2:-60}" "${3:-5}"
            ;;
        "security-scan")
            security_scan "${2:-}" "${3:-table}" "${4:-HIGH,CRITICAL}" "${5:-security_scan_results_$(date +%Y%m%d_%H%M%S).log}" "${6:-false}"
            ;;
        "batch-operation")
            batch_operation "${2:-}" "${3:-}" "${4:-false}"
            ;;
        "resource-report")
            resource_monitor_report "${2:-60}" "${3:-5}"
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