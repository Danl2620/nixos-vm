ssh_port := "2223"
ssh_user := "nixos"

# List available tasks
default:
    @just --list

# SSH into the running VM
ssh:
    ssh -p {{ssh_port}} {{ssh_user}}@localhost

# Add VM host key to known_hosts
trust-host-key:
    ssh-keyscan -p {{ssh_port}} localhost >> ~/.ssh/known_hosts

# Remove VM host key from known_hosts (useful after VM reinstall)
forget-host-key:
    ssh-keygen -R "[localhost]:{{ssh_port}}"

# Kill all running QEMU processes
kill-vm:
    pkill qemu-system-x86_64 || true

# Format nix files
fmt:
    nix fmt

# Run flake checks
check:
    nix flake check

# Copy a file into the VM via scp
scp-to file dest="/tmp":
    scp -P {{ssh_port}} {{file}} {{ssh_user}}@localhost:{{dest}}

# Copy a file from the VM via scp
scp-from file dest=".":
    scp -P {{ssh_port}} {{ssh_user}}@localhost:{{file}} {{dest}}
