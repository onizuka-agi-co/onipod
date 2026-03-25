# Podman Manager Script

Enhanced monitoring and management tool for Podman containers with advanced notification and alerting capabilities.

## Overview

The Podman Manager Script is a comprehensive utility designed to simplify container management with Podman. It includes advanced monitoring features with notifications, health checking, resource monitoring, and automated alerting capabilities to help maintain reliable containerized applications.

## Features

- **Container Management**: Start, stop, restart, and manage containers
- **Monitoring**: Real-time resource monitoring with configurable thresholds
- **Health Checking**: Automated health status verification for containers
- **Notifications & Alerts**: Email and desktop notifications for critical events
- **Resource Monitoring**: CPU and memory usage tracking with alerting
- **Secure Container Creation**: Security-first container creation with best practices
- **Detailed Logging**: Comprehensive activity logging to `/tmp/podman_manager.sh.log`

## Installation

1. Make sure you have Podman installed:
   ```bash
   # On Fedora/RHEL
   sudo dnf install podman

   # On Ubuntu/Debian
   sudo apt install podman
   ```

2. Ensure the script is executable:
   ```bash
   chmod +x /workspace/deliverables/podman_manager.sh
   ```

## Configuration

The script supports optional configuration through a YAML file at `~/.config/oni-pod/config.yaml`. Available options include:

```yaml
alert_email: "admin@example.com"  # Email address for alerts
resource_threshold_cpu: 80        # CPU usage percentage threshold
resource_threshold_mem: 80        # Memory usage percentage threshold
```

You can also set these values using environment variables:
- `ALERT_EMAIL`
- `RESOURCE_THRESHOLD_CPU`
- `RESOURCE_THRESHOLD_MEM`

## Usage

### Basic Commands

- List all containers: `./podman_manager.sh list`
- Show container status: `./podman_manager.sh status <container_id>`
- Start a container: `./podman_manager.sh start <container_id>`
- Stop a container: `./podman_manager.sh stop <container_id>`
- Restart a container: `./podman_manager.sh restart <container_id>`
- View container logs: `./podman_manager.sh logs <container_id>`
- Follow container logs: `./podman_manager.sh logs <container_id> follow`
- View container details: `./podman_manager.sh inspect <container_id>`

### Advanced Features

- Monitor all containers: `./podman_manager.sh monitor`
- Monitor with alerts: `./podman_manager.sh monitor-alerts`
- Perform health check: `./podman_manager.sh health-check`
- Health check specific container: `./podman_manager.sh health-check <container_name>`
- Check resource usage: `./podman_manager.sh check-resources <container_id>`
- Show detailed resource usage: `./podman_manager.sh resources`
- Execute command in container: `./podman_manager.sh exec <container_id> <command>`
- Create secure container: `./podman_manager.sh create <image> <name> [options]`
- Remove container: `./podman_manager.sh remove <container_id>`
- Clean up unused resources: `./podman_manager.sh prune`

### Notification System

The script provides comprehensive notification capabilities:
- Desktop notifications via `notify-send` (if available)
- Email alerts to configured addresses (if `mail` command is available)
- Log entries in `/tmp/podman_manager.sh.log`

Alerts trigger for:
- High CPU or memory usage (based on configurable thresholds)
- Container crashes or unexpected shutdowns
- Unhealthy container status
- Non-zero exit codes from containers

### Examples

```bash
# Create and start a secure nginx container
./podman_manager.sh create nginx my-nginx -p 8080:80

# Monitor all containers with real-time alerts
./podman_manager.sh monitor-alerts

# Check resource usage of a specific container
./podman_manager.sh check-resources my-container-id

# Perform health check on all containers
./podman_manager.sh health-check

# Execute a command in a running container
./podman_manager.sh exec my-container bash
```

## Dependencies

- Podman
- Bash 4.0+
- `jq` (for detailed resource metrics)
- `mail` (for email notifications)
- `notify-send` (for desktop notifications)
- `yq` (for YAML configuration parsing)

## Support

If you encounter issues with the script, please check the log file at `/tmp/podman_manager.sh.log` for detailed information about errors and system activities.

## License

MIT License - See LICENSE file for details.