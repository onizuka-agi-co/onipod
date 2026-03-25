# Oni Pod Implementation

This directory contains the complete implementation of the Oni Pod secure container runtime as specified in the design document.

## Files Included

### Core Components

1. **`oni_pod.sh`** - Main entry point that orchestrates all Oni Pod functionality
2. **`oni_pod_manager.sh`** - Core container management functionality (start, stop, status, logs, etc.)
3. **`oni_pod_monitoring.sh`** - Monitoring and logging system with health checks
4. **`oni_pod_security_layer.sh`** - Security controls and validation
5. **`oni_pod_systemd_manager.sh`** - Systemd integration for container services
6. **`oni_pod_config.yaml`** - Default configuration following the YAML format specified

### Features Implemented

Based on the design document, the following features have been implemented:

#### Container Management (Section 3.1)
- List all containers
- Check container status
- Start/stop/restart containers
- View container logs
- Continuous monitoring
- Health checks

#### Security Layer (Section 3.2)
- Rootless container execution
- Read-only root filesystem enforcement
- Capability dropping
- Seccomp filtering
- User namespace mapping
- Security validation checks

#### Monitoring & Logging (Section 3.3)
- Container metrics collection
- Continuous monitoring
- Health status checking
- Log aggregation
- Resource trend monitoring
- Alert notification system

#### Configuration Management (Section 3.4)
- YAML-based configuration
- Default security policies
- Runtime parameters

### Usage

#### Basic Operations
```bash
# Initialize Oni Pod environment
./oni_pod.sh init

# Show system dashboard
./oni_pod.sh dashboard

# Run system check
./oni_pod.sh check

# Create a sample container
./oni_pod.sh create-sample alpine test-container
```

#### Direct Module Access
```bash
# Container management
./oni_pod.sh run-manager list
./oni_pod.sh run-manager status <container_name>
./oni_pod.sh run-manager start <container_name>

# Monitoring
./oni_pod.sh run-monitoring health-check <container_name>
./oni_pod.sh run-monitoring monitor-all

# Security
./oni_pod.sh run-security check-container <container_name>
./oni_pod.sh run-security validate-config
```

#### Direct Script Access
```bash
# Using manager directly
./oni_pod_manager.sh list
./oni_pod_manager.sh status <container_name>

# Using monitoring directly
./oni_pod_monitoring.sh metrics <container_name>

# Using security directly
./oni_pod_security_layer.sh check-container <container_name>
```

### Architecture

The implementation follows the modular architecture specified in the design document:

```
+-------------------------+
|    ユーザーインターフェース      |
+-------------------------+
|    管理コマンド (CLI)        |
+-------------------------+
|    Oni Podコアサービス      |
+-------------------------+
|    Podmanランタイム         |
+-------------------------+
|    Linuxカーネル (namespaces, cgroups) |
+-------------------------+
```

Each component handles its specific responsibilities while integrating closely with Podman as the underlying container runtime.

### Security Features

The implementation enforces the security measures specified in Section 6:
- Rootless execution
- Seccomp-BPF filtering
- Capability restrictions
- User namespace isolation
- SELinux integration
- Read-only root filesystem

### Integration with Podman

As specified in Section 5, Oni Pod integrates with Podman by:
- Using Podman CLI commands internally
- Leveraging Podman's security features
- Maintaining compatibility with Podman-created containers
- Supporting all Podman options through the wrapper layer

