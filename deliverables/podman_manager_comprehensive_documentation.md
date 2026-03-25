# Podman Container Manager Script - Comprehensive Documentation

## Overview

`podman_manager.sh` is a comprehensive bash script designed to simplify Podman container management. It provides a user-friendly interface for common container operations such as listing, starting, stopping, monitoring, logging, and removing containers. The script includes error handling, colored output for better visibility, and continuous monitoring capabilities.

## Prerequisites

- Podman installed and properly configured on your system
- Basic understanding of Podman concepts
- Bash shell environment
- Optional: `jq` installed for enhanced statistics output

## Installation and Setup

1. Download or copy the `podman_manager.sh` script to your desired location
2. Set executable permissions:
   ```bash
   chmod +x podman_manager.sh
   ```

## Usage

Basic syntax:
```bash
./podman_manager.sh [COMMAND] [OPTIONS]
```

## Commands

### list
Lists all containers (both running and stopped).

Example:
```bash
./podman_manager.sh list
```

### ps
Shows only running containers.

Example:
```bash
./podman_manager.sh ps
```

### logs CONTAINER_NAME
Displays logs for a specific container.

Example:
```bash
./podman_manager.sh logs mycontainer
```

### start CONTAINER_NAME
Starts a specified container.

Example:
```bash
./podman_manager.sh start mycontainer
```

### stop CONTAINER_NAME
Stops a specified container.

Example:
```bash
./podman_manager.sh stop mycontainer
```

### restart CONTAINER_NAME
Restarts a specified container.

Example:
```bash
./podman_manager.sh restart mycontainer
```

### remove CONTAINER_NAME
Removes a specified container (forcefully stops if running).

Example:
```bash
./podman_manager.sh remove mycontainer
```

### status CONTAINER_NAME
Shows detailed status information for a specific container including basic info, resource usage, and detailed inspection data.

Example:
```bash
./podman_manager.sh status mycontainer
```

### stats
Displays resource usage statistics for all running containers.

Example:
```bash
./podman_manager.sh stats
```

### monitor
Continuously monitors all containers with color-coded status updates. Press Ctrl+C to exit.

Example:
```bash
./podman_manager.sh monitor
```

### help
Displays the help message with all available commands.

Example:
```bash
./podman_manager.sh help
```
or
```bash
./podman_manager.sh -h
```

## Color Coding

The script uses color coding to help distinguish different types of information:
- **Green**: Success messages and running containers
- **Red**: Error messages and stopped containers
- **Yellow**: Warning messages and containers in transitional states
- **Blue**: Informational messages and headers

## Examples

### 1. View All Containers
```bash
./podman_manager.sh list
```

### 2. Manage a Container
```bash
# Start a container
./podman_manager.sh start mywebapp

# Check its status
./podman_manager.sh status mywebapp

# View its logs
./podman_manager.sh logs mywebapp

# Stop the container
./podman_manager.sh stop mywebapp
```

### 3. Monitor Container Status Continuously
```bash
./podman_manager.sh monitor
```

### 4. Resource Usage Statistics
```bash
./podman_manager.sh stats
```

### 5. Remove a Container
```bash
./podman_manager.sh remove my-old-container
```

## Error Handling

The script includes comprehensive error handling:

1. **Podman Check**: Verifies that Podman is installed and accessible before executing commands.
2. **Parameter Validation**: Ensures required parameters like container names are provided.
3. **Container Existence**: Checks if containers exist before performing operations on them.
4. **Operation Feedback**: Provides clear success or failure messages for each operation.

Common error scenarios:
- Podman not installed: Script exits with error message
- Invalid container name: Appropriate error message displayed
- Insufficient permissions: Error message indicating permission issues

## Features

1. **Colored Output**: Makes it easy to identify status and results at a glance
2. **Error Resilience**: Handles common error scenarios gracefully
3. **Continuous Monitoring**: Real-time container status monitoring capability
4. **Detailed Status Reports**: Comprehensive container inspection
5. **User-Friendly Interface**: Simple command structure with clear help

## Security Considerations

- The script executes Podman commands as the current user
- It respects Podman's security model (root vs rootless)
- No hardcoded credentials or sensitive information stored in the script

## Troubleshooting

Q: Script fails with "Podman is not installed or not in PATH"
A: Ensure Podman is installed and accessible from your command line. You can verify this by running `podman --version`

Q: Command fails with permission error
A: Ensure you have appropriate permissions to manage the target containers. Rootless Podman should work for user containers.

Q: Monitor command doesn't refresh properly
A: The script refreshes every 5 seconds. If experiencing display issues, try resizing your terminal window.

Q: Some statistics are not showing
A: Install `jq` for enhanced statistics output with additional details.

## Integration with Existing Workflows

This script can be integrated into existing DevOps workflows, used in automated scripts, or serve as a utility for developers managing containerized applications.

To add to PATH for global access:
1. Move script to a directory in your PATH: `sudo cp podman_manager.sh /usr/local/bin/`
2. Or add script location to your PATH in `.bashrc` or `.zshrc`