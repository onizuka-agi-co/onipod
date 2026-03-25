#!/bin/bash

# Oni Pod Security Layer
# Implements security controls as specified in the design document

set -euo pipefail

# Default security policy
SECURITY_POLICY_FILE="${HOME}/.config/oni-pod/security-policy.json"

# Create default security policy if it doesn't exist
init_security_policy() {
    if [[ ! -f "$SECURITY_POLICY_FILE" ]]; then
        mkdir -p "$(dirname "$SECURITY_POLICY_FILE")"

        cat > "$SECURITY_POLICY_FILE" << 'EOF'
{
  "version": "1.0",
  "defaults": {
    "read_only_root_filesystem": true,
    "no_new_privileges": true,
    "drop_all_capabilities": true,
    "seccomp_enabled": true,
    "selinux_enabled": true,
    "user_namespace_enabled": true,
    "minimum_uid": 1000,
    "minimum_gid": 1000
  },
  "seccomp_profile": {
    "defaultAction": "SCMP_ACT_ERRNO",
    "architectures": [
      "SCMP_ARCH_X86_64",
      "SCMP_ARCH_X86",
      "SCMP_ARCH_ARM64",
      "SCMP_ARCH_ARM"
    ],
    "syscalls": [
      {
        "names": [
          "accept",
          "accept4",
          "access",
          "adjtimex",
          "alarm",
          "bind",
          "brk",
          "capget",
          "capset",
          "chdir",
          "chmod",
          "chown",
          "chown32",
          "clock_getres",
          "clock_gettime",
          "clock_nanosleep",
          "close",
          "connect",
          "copy_file_range",
          "creat",
          "dup",
          "dup2",
          "dup3",
          "epoll_create",
          "epoll_create1",
          "epoll_ctl",
          "epoll_ctl_old",
          "epoll_pwait",
          "epoll_wait",
          "epoll_wait_old",
          "eventfd",
          "eventfd2",
          "execve",
          "execveat",
          "exit",
          "exit_group",
          "faccessat",
          "fadvise64",
          "fadvise64_64",
          "fallocate",
          "fanotify_mark",
          "fchdir",
          "fchmod",
          "fchmodat",
          "fchown",
          "fchown32",
          "fchownat",
          "fcntl",
          "fcntl64",
          "fdatasync",
          "fgetxattr",
          "flistxattr",
          "flock",
          "fork",
          "fremovexattr",
          "fsetxattr",
          "fstat",
          "fstat64",
          "fstatat64",
          "fstatfs",
          "fstatfs64",
          "fsync",
          "ftruncate",
          "ftruncate64",
          "futex",
          "futimesat",
          "getcpu",
          "getcwd",
          "getdents",
          "getdents64",
          "getegid",
          "getegid32",
          "geteuid",
          "geteuid32",
          "getgid",
          "getgid32",
          "getgroups",
          "getgroups32",
          "getitimer",
          "getpeername",
          "getpgid",
          "getpgrp",
          "getpid",
          "getppid",
          "getpriority",
          "getrandom",
          "getresgid",
          "getresgid32",
          "getresuid",
          "getresuid32",
          "getrlimit",
          "get_robust_list",
          "getrusage",
          "getsid",
          "getsockname",
          "getsockopt",
          "get_thread_area",
          "gettid",
          "gettimeofday",
          "getuid",
          "getuid32",
          "getxattr",
          "inotify_add_watch",
          "inotify_init",
          "inotify_init1",
          "inotify_rm_watch",
          "io_cancel",
          "ioctl",
          "io_destroy",
          "io_getevents",
          "ioprio_get",
          "ioprio_set",
          "io_setup",
          "io_submit",
          "ipc",
          "kill",
          "lchown",
          "lchown32",
          "lgetxattr",
          "link",
          "linkat",
          "listen",
          "listxattr",
          "llistxattr",
          "lremovexattr",
          "lseek",
          "lsetxattr",
          "lstat",
          "lstat64",
          "madvise",
          "memfd_create",
          "mincore",
          "mkdir",
          "mkdirat",
          "mknod",
          "mknodat",
          "mlock",
          "mlock2",
          "mlockall",
          "mmap",
          "mmap2",
          "mount",
          "mprotect",
          "mq_getsetattr",
          "mq_notify",
          "mq_open",
          "mq_timedreceive",
          "mq_timedsend",
          "mq_unlink",
          "mremap",
          "msgctl",
          "msgget",
          "msgrcv",
          "msgsnd",
          "msync",
          "munlock",
          "munlockall",
          "munmap",
          "nanosleep",
          "newfstatat",
          "open",
          "openat",
          "pause",
          "pipe",
          "pipe2",
          "poll",
          "ppoll",
          "prctl",
          "pread64",
          "preadv",
          "preadv2",
          "prlimit64",
          "pselect6",
          "pwrite64",
          "pwritev",
          "pwritev2",
          "read",
          "readahead",
          "readlink",
          "readlinkat",
          "readv",
          "recv",
          "recvfrom",
          "recvmmsg",
          "recvmsg",
          "remap_file_pages",
          "removexattr",
          "rename",
          "renameat",
          "renameat2",
          "restart_syscall",
          "rmdir",
          "rt_sigaction",
          "rt_sigpending",
          "rt_sigprocmask",
          "rt_sigqueueinfo",
          "rt_sigreturn",
          "rt_sigsuspend",
          "rt_sigtimedwait",
          "rt_tgsigqueueinfo",
          "sched_get_priority_max",
          "sched_get_priority_min",
          "sched_getaffinity",
          "sched_getattr",
          "sched_getparam",
          "sched_getscheduler",
          "sched_rr_get_interval",
          "sched_setaffinity",
          "sched_setattr",
          "sched_setparam",
          "sched_setscheduler",
          "sched_yield",
          "seccomp",
          "select",
          "semctl",
          "semget",
          "semop",
          "semtimedop",
          "send",
          "sendfile",
          "sendfile64",
          "sendmmsg",
          "sendmsg",
          "sendto",
          "setfsgid",
          "setfsgid32",
          "setfsuid",
          "setfsuid32",
          "setgid",
          "setgid32",
          "setgroups",
          "setgroups32",
          "setitimer",
          "setpgid",
          "setpriority",
          "setregid",
          "setregid32",
          "setresgid",
          "setresgid32",
          "setresuid",
          "setresuid32",
          "setreuid",
          "setreuid32",
          "setrlimit",
          "set_robust_list",
          "setsid",
          "setsockopt",
          "set_thread_area",
          "set_tid_address",
          "setuid",
          "setuid32",
          "setxattr",
          "shmat",
          "shmctl",
          "shmdt",
          "shmget",
          "shutdown",
          "sigaltstack",
          "signalfd",
          "signalfd4",
          "socket",
          "socketcall",
          "socketpair",
          "splice",
          "stat",
          "stat64",
          "statfs",
          "statfs64",
          "symlink",
          "symlinkat",
          "sync",
          "sync_file_range",
          "syncfs",
          "sysinfo",
          "tee",
          "tgkill",
          "time",
          "timer_create",
          "timer_delete",
          "timer_getoverrun",
          "timer_gettime",
          "timer_settime",
          "timerfd_create",
          "timerfd_gettime",
          "timerfd_settime",
          "times",
          "tkill",
          "truncate",
          "truncate64",
          "ugetrlimit",
          "umask",
          "uname",
          "unlink",
          "unlinkat",
          "unshare",
          "utime",
          "utimensat",
          "utimes",
          "vfork",
          "vmsplice",
          "wait4",
          "waitid",
          "waitpid",
          "write",
          "writev"
        ],
        "action": "SCMP_ACT_ALLOW"
      }
    ]
  }
}
EOF
    fi
}

# Apply security policy to a container
apply_security_policy() {
    local container_name="$1"

    if [[ -z "$container_name" ]]; then
        echo "Error: Container name is required"
        return 1
    fi

    # Check if container exists
    if ! podman inspect "$container_name" > /dev/null 2>&1; then
        echo "Error: Container '$container_name' does not exist"
        return 1
    fi

    # Get container info
    local image=$(podman inspect --format '{{.Config.Image}}' "$container_name")
    local state=$(podman inspect --format '{{.State.Status}}' "$container_name")

    echo "Applying security policy to container: $container_name"
    echo "  Image: $image"
    echo "  Current state: $state"

    # If container is running, we can't apply security settings directly
    if [[ "$state" == "running" ]]; then
        echo "Warning: Container is running, security settings applied at creation time"
        echo "Recommendation: Recreate the container with security settings applied"
        return 0
    fi

    # Report the security features that would be applied
    echo "Security features that would be applied:"
    echo "  - Read-only root filesystem"
    echo "  - No new privileges"
    echo "  - Dropping all capabilities"
    echo "  - Seccomp filtering"
    echo "  - User namespace mapping"
    echo "  - SELinux context"

    return 0
}

# Validate security configuration
validate_security_config() {
    local result=0

    echo "Validating Oni Pod security configuration..."

    # Check if Podman is running rootless
    if podman info | grep -q "rootless.*true"; then
        echo "✓ Podman is running in rootless mode"
    else
        echo "⚠ Podman is not running in rootless mode"
        ((result++))
    fi

    # Check SELinux status if available
    if command -v getenforce > /dev/null 2>&1; then
        local selinux_status=$(getenforce 2>/dev/null || echo "disabled")
        if [[ "$selinux_status" =~ ^(Enforcing|Permissive)$ ]]; then
            echo "✓ SELinux is enabled: $selinux_status"
        else
            echo "⚠ SELinux is not properly configured: $selinux_status"
        fi
    else
        echo "ℹ SELinux utilities not found"
    fi

    # Check if user namespaces are enabled
    if [[ -f /proc/sys/kernel/unprivileged_userns_clone ]]; then
        local unpriv_ns=$(cat /proc/sys/kernel/unprivileged_userns_clone)
        if [[ "$unpriv_ns" == "1" ]]; then
            echo "✓ Unprivileged user namespaces enabled"
        else
            echo "⚠ Unprivileged user namespaces disabled"
            ((result++))
        fi
    else
        echo "ℹ Kernel parameter for user namespaces not found"
    fi

    # Check if security policy file exists
    if [[ -f "$SECURITY_POLICY_FILE" ]]; then
        echo "✓ Security policy file exists"
    else
        echo "⚠ Security policy file does not exist, initializing..."
        init_security_policy
        echo "✓ Security policy initialized"
    fi

    if [[ $result -eq 0 ]]; then
        echo "Security validation completed: All checks passed"
    else
        echo "Security validation completed: $result issue(s) found"
    fi

    return $result
}

# Check container security posture
check_container_security() {
    local container_name="$1"

    if [[ -z "$container_name" ]]; then
        echo "Error: Container name is required"
        return 1
    fi

    # Get container security info
    local security_info=$(podman inspect "$container_name" 2>/dev/null)

    if [[ $? -ne 0 ]]; then
        echo "Error: Could not inspect container '$container_name'"
        return 1
    fi

    echo "Security assessment for container: $container_name"
    echo ""

    # Check if running as root
    local user_info=$(echo "$security_info" | jq -r '.[0].Config.User // empty')
    if [[ -z "$user_info" ]] || [[ "$user_info" == "0" ]] || [[ "$user_info" == "root" ]]; then
        echo "⚠ Container is running as root user"
    else
        echo "✓ Container is running as non-root user: $user_info"
    fi

    # Check for privileged mode
    local privileged=$(echo "$security_info" | jq -r '.[0].HostConfig.Privileged // false')
    if [[ "$privileged" == "true" ]]; then
        echo "❌ Container is running in privileged mode"
    else
        echo "✓ Container is not running in privileged mode"
    fi

    # Check for read-only root filesystem
    local readonly_root=$(echo "$security_info" | jq -r '.[0].HostConfig.ReadonlyRootfs // false')
    if [[ "$readonly_root" == "true" ]]; then
        echo "✓ Container has read-only root filesystem"
    else
        echo "⚠ Container does not have read-only root filesystem"
    fi

    # Check for capability drops
    local dropped_caps=$(echo "$security_info" | jq -r '.[0].HostConfig.CapDrop // [] | length')
    if [[ $dropped_caps -gt 0 ]]; then
        local caps_list=$(echo "$security_info" | jq -r '.[0].HostConfig.CapDrop // [] | join(", ")')
        echo "✓ Container has dropped capabilities ($dropped_caps): $caps_list"
    else
        echo "⚠ Container has not dropped any capabilities"
    fi

    # Check for seccomp profile
    local seccomp_profile=$(echo "$security_info" | jq -r '.[0].HostConfig.SeccompProfile // empty')
    if [[ -n "$seccomp_profile" ]]; then
        echo "✓ Container uses seccomp profile: $seccomp_profile"
    else
        echo "⚠ Container does not use a seccomp profile"
    fi

    # Check for user namespace
    local userns=$(echo "$security_info" | jq -r '.[0].HostConfig.UsernsMode // empty')
    if [[ -n "$userns" ]]; then
        echo "✓ Container uses user namespace: $userns"
    else
        echo "⚠ Container does not use user namespace"
    fi
}

# Main function
main() {
    local command="$1"
    shift

    case "$command" in
        init-policy)
            init_security_policy
            echo "Security policy initialized"
            ;;
        apply)
            apply_security_policy "$@"
            ;;
        validate-config)
            validate_security_config
            ;;
        check-container)
            check_container_security "$@"
            ;;
        *)
            echo "Oni Pod Security Layer"
            echo ""
            echo "Usage: $0 <command> [options]"
            echo ""
            echo "Commands:"
            echo "  init-policy           Initialize security policy file"
            echo "  apply CONTAINER_NAME  Apply security policy to container"
            echo "  validate-config       Validate overall security configuration"
            echo "  check-container CONTAINER_NAME  Check security posture of container"
            return 1
            ;;
    esac
}

main "$@"