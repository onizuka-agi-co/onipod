# Contributing to Podman Manager Script

Thank you for your interest in contributing to the Podman Manager Script! This document outlines the guidelines for contributing to this project.

## Table of Contents

- [Development Setup](#development-setup)
- [Project Structure](#project-structure)
- [Code Style](#code-style)
- [Feature Requests and Bug Reports](#feature-requests-and-bug-reports)
- [Pull Request Process](#pull-request-process)
- [Testing](#testing)
- [Notification and Alerting System](#notification-and-alerting-system)
- [Security Considerations](#security-considerations)

## Development Setup

To get started with development:

1. Fork the repository
2. Clone your fork locally:
   ```bash
   git clone <your-fork-url>
   ```
3. Navigate to the deliverables directory:
   ```bash
   cd deliverables
   ```
4. Ensure you have the required dependencies installed:
   - Podman
   - Bash 4.0+
   - `jq` (for detailed resource metrics)
   - `mail` (for email notifications)
   - `notify-send` (for desktop notifications)
   - `yq` (for YAML configuration parsing)

## Project Structure

```
deliverables/
├── podman_manager.sh          # Main script containing all functionality
└── README_PODMAN_MANAGER.md   # Documentation for the script
```

The `podman_manager.sh` script is organized into the following main sections:
- Configuration and global variables
- Logging and notification functions
- Container management functions
- Monitoring and alerting functions
- Health check functions
- Main command router

## Code Style

We follow bash best practices:

- Use `readonly` for constants
- Use `local` for function variables
- Follow the `snake_case` naming convention for functions and variables
- Always quote variables to prevent word splitting
- Use `set -euo pipefail` for error handling
- Add comprehensive logging with the `log()` function
- Provide helpful error messages when operations fail

Function documentation should follow this format:

```bash
# Function description
# Arguments:
#   $1 - argument description
#   $2 - argument description (optional)
# Returns:
#   0 on success, non-zero on failure
function_name() {
    # function body
}
```

## Feature Requests and Bug Reports

Before submitting a feature request or bug report:

1. Search existing issues to see if your concern has already been reported
2. When filing an issue, include:
   - A clear description of the problem or feature
   - Steps to reproduce the issue (for bugs)
   - Expected vs. actual behavior
   - System information (OS, Podman version, Bash version)

## Pull Request Process

1. Ensure your PR addresses a specific issue or need
2. Update the README documentation if you've added new features
3. Follow the existing code style and patterns
4. Test your changes thoroughly
5. Submit your PR with a clear title and description
6. Be responsive to feedback during the review process

## Testing

When contributing code, please test the following scenarios:

- Normal operation of the new functionality
- Error conditions and edge cases
- Compatibility with different container images
- Correct behavior when dependencies are missing
- Proper handling of resource limits

To manually test the script:

1. Run basic operations:
   ```bash
   ./podman_manager.sh list
   ./podman_manager.sh status <container_id>
   ```
2. Test monitoring functions:
   ```bash
   ./podman_manager.sh monitor
   ./podman_manager.sh check-resources <container_id>
   ```
3. Verify notification functionality with the configured alert system

## Notification and Alerting System

The notification system is a key feature of this script. When contributing to this system:

- Maintain compatibility with both email and desktop notifications
- Ensure notifications include sufficient context to understand the issue
- Respect user configuration for thresholds and notification methods
- Keep the notification code separate from core logic

The main notification functions are:
- `send_notification()` - Primary function for sending notifications
- `check_resource_usage()` - Checks resource thresholds and triggers alerts
- `monitor_container_health()` - Monitors health and sends failure notifications

## Security Considerations

This script implements security best practices for container management. When making changes:

- Preserve existing security measures (read-only filesystems, limited capabilities, etc.)
- Validate all inputs to prevent injection attacks
- Sanitize container IDs and names before using them in commands
- Don't introduce new shell injection vulnerabilities

Secure container creation uses these principles:
- Rootless execution by default
- Read-only root filesystem (`--read-only`)
- No new privileges (`--security-opt=no-new-privileges`)
- Automatic user namespace mapping (`--userns=auto`)

## Getting Help

If you have questions about contributing:

- Check the existing documentation
- Open an issue with your question
- Examine existing code for examples of proper implementation