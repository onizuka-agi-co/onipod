#!/bin/bash

# Oni Pod Systemd Service Manager
# Handles systemd integration for Oni Pod containers

set -euo pipefail

CONFIG_FILE="${HOME}/.config/oni-pod/config.yaml"
SYSTEMD_USER_DIR="${HOME}/.config/systemd/user"

# Load configuration
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        # Parse YAML configuration (simple approach for this implementation)
        SYSTEMD_ENABLED=$(grep -E "^enable_systemd:" "$CONFIG_FILE" | awk '{print $2}' | tr -d '"')
    else
        SYSTEMD_ENABLED="false"
    fi
}

# Create systemd service for a container
create_service() {
    local container_name="$1"
    if [[ -z "$container_name" ]]; then
        echo "Error: Container name is required"
        return 1
    fi

    if [[ "$SYSTEMD_ENABLED" != "true" && "$SYSTEMD_ENABLED" != "True" ]]; then
        echo "Systemd integration is not enabled in configuration"
        return 1
    fi

    mkdir -p "$SYSTEMD_USER_DIR"

    local service_file="$SYSTEMD_USER_DIR/oni-pod-$container_name.service"

    cat > "$service_file" << EOF
[Unit]
Description=Oni Pod Container - $container_name
After=network.target
Requires=podman.socket

[Service]
Type=notify
NotifyAccess=all
Environment=PODMAN_SYSTEMD_UNIT=%n
Restart=on-failure
RestartSec=30
TimeoutStartSec=0
ExecStartPre=/bin/rm -f %t/%n.ctr-id
ExecStart=/usr/bin/podman run \
    --cidfile=%t/%n.ctr-id \
    --cgroups=no-conmon \
    --rm \
    --sdnotify=conmon \
    --replace \
    $container_name
ExecStop=/usr/bin/podman stop --ignore --cidfile=%t/%n.ctr-id
ExecStopPost=/usr/bin/podman rm -f --ignore --cidfile=%t/%n.ctr-id
PIDFile=%t/%n.ctr-id
KillMode=none
Type=forking

[Install]
WantedBy=default.target
EOF

    echo "Created systemd service for container: $container_name"
    echo "Service file: $service_file"

    # Reload systemd daemon
    systemctl --user daemon-reload

    echo "To enable the service, run: systemctl --user enable oni-pod-$container_name.service"
    echo "To start the service, run: systemctl --user start oni-pod-$container_name.service"
}

# Generate systemd unit file for a running container
generate_unit_file() {
    local container_name="$1"
    if [[ -z "$container_name" ]]; then
        echo "Error: Container name is required"
        return 1
    fi

    # Get container details using podman
    local image=$(podman inspect --format '{{.Config.Image}}' "$container_name" 2>/dev/null)
    if [[ $? -ne 0 ]]; then
        echo "Error: Container '$container_name' not found"
        return 1
    fi

    # Extract port mappings
    local ports_raw=$(podman inspect --format '{{range .NetworkSettings.Ports}}{{.}}{{end}}' "$container_name")
    local ports=""
    if [[ -n "$ports_raw" ]]; then
        # Process ports for systemd socket activation if needed
        ports="# Port mappings would be handled here"
    fi

    # Get environment variables
    local env_vars=$(podman inspect --format '{{range .Config.Env}}Environment={{println .}}{{end}}' "$container_name")

    # Create the unit file
    local service_file="$SYSTEMD_USER_DIR/oni-pod-$container_name.container"

    cat > "$service_file" << EOF
# Auto-generated systemd unit for Oni Pod container: $container_name
[Unit]
Description=Oni Pod Container - $container_name
After=network.target
Requires=podman.socket

[Container]
Image=$image
# Environment variables
$env_vars
# Add volumes, ports, etc. as needed

[Install]
WantedBy=default.target
EOF

    echo "Generated systemd unit file for container: $container_name"
    echo "Unit file: $service_file"

    # Reload systemd daemon
    systemctl --user daemon-reload
}

# Enable systemd integration
enable_systemd() {
    # Update config to enable systemd
    if [[ -f "$CONFIG_FILE" ]]; then
        sed -i 's/enable_systemd:.*/enable_systemd: true/' "$CONFIG_FILE"
    else
        echo "Configuration file does not exist, creating with systemd enabled"
        mkdir -p "$(dirname "$CONFIG_FILE")"
        cat > "$CONFIG_FILE" << EOF
# Oni Pod Configuration
enable_systemd: true
EOF
    fi

    echo "Systemd integration enabled"
}

# Disable systemd integration
disable_systemd() {
    if [[ -f "$CONFIG_FILE" ]]; then
        sed -i 's/enable_systemd:.*/enable_systemd: false/' "$CONFIG_FILE"
    fi

    echo "Systemd integration disabled"
}

# List systemd services for Oni Pod
list_services() {
    systemctl --user list-units --type=service | grep "oni-pod-" || echo "No Oni Pod services found"
}

# Main function
main() {
    local command="$1"
    shift

    load_config

    case "$command" in
        create-service)
            create_service "$@"
            ;;
        generate-unit)
            generate_unit_file "$@"
            ;;
        enable)
            enable_systemd
            ;;
        disable)
            disable_systemd
            ;;
        list)
            list_services
            ;;
        *)
            echo "Oni Pod Systemd Manager"
            echo ""
            echo "Usage: $0 <command> [options]"
            echo ""
            echo "Commands:"
            echo "  create-service CONTAINER_NAME   Create systemd service for container"
            echo "  generate-unit CONTAINER_NAME    Generate systemd unit file for container"
            echo "  enable                        Enable systemd integration"
            echo "  disable                       Disable systemd integration"
            echo "  list                          List Oni Pod systemd services"
            return 1
            ;;
    esac
}

main "$@"