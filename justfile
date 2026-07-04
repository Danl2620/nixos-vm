ssh_port := "2223"
ssh_user := "nixos"
vm_name := "nixos-vm"
vm_disk := vm_name + ".qcow2"
vm_disk_size := "20G"
vm_memory := "2048"
vm_cpus := "2"
iso_url := "https://channels.nixos.org/nixos-24.11/latest-nixos-minimal-x86_64-linux.iso"
iso_file := "nixos-minimal.iso"

# List available tasks
default:
    @just --list

# SSH into the running VM
[group('ssh')]
ssh:
    ssh -p {{ssh_port}} {{ssh_user}}@localhost

# Add VM host key to known_hosts
[group('ssh')]
trust-host-key:
    ssh-keyscan -p {{ssh_port}} localhost >> ~/.ssh/known_hosts

# Remove VM host key from known_hosts (useful after VM reinstall)
[group('ssh')]
forget-host-key:
    ssh-keygen -R "[localhost]:{{ssh_port}}"

# Copy a file into the VM via scp
[group('ssh')]
scp-to file dest="/tmp":
    scp -P {{ssh_port}} {{file}} {{ssh_user}}@localhost:{{dest}}

# Copy a file from the VM via scp
[group('ssh')]
scp-from file dest=".":
    scp -P {{ssh_port}} {{ssh_user}}@localhost:{{file}} {{dest}}

# Create a virtual disk for the VM
[group('vm')]
create-disk:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ -f "{{vm_disk}}" ]; then
        echo "Disk {{vm_disk}} already exists. Delete it first to recreate."
        exit 1
    fi
    qemu-img create -f qcow2 "{{vm_disk}}" "{{vm_disk_size}}"
    echo "Created {{vm_disk}} ({{vm_disk_size}})"

# Download the latest NixOS minimal ISO
[group('vm')]
fetch-iso:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ -f "{{iso_file}}" ]; then
        echo "{{iso_file}} already exists. Delete it to re-download."
        exit 1
    fi
    echo "Downloading NixOS minimal ISO..."
    curl -L -o "{{iso_file}}" "{{iso_url}}"
    echo "Downloaded {{iso_file}}"

# Boot the NixOS installer ISO
[group('vm')]
boot-installer:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ ! -f "{{iso_file}}" ]; then
        echo "No ISO found. Run 'just fetch-iso' first."
        exit 1
    fi
    if [ ! -f "{{vm_disk}}" ]; then
        echo "No disk found. Run 'just create-disk' first."
        exit 1
    fi
    echo "Booting NixOS installer (graphical window)..."
    echo "  SSH will be available on localhost:{{ssh_port}} once you set a password"
    echo "  Close the QEMU window or use the monitor to quit"
    echo ""
    qemu-system-x86_64 \
        -m "{{vm_memory}}" \
        -smp "{{vm_cpus}}" \
        -cdrom "{{iso_file}}" \
        -boot d \
        -drive "file={{vm_disk}},format=qcow2" \
        -nic "user,hostfwd=tcp::{{ssh_port}}-:22" \
        -virtfs "local,path=.,mount_tag=nixos-config,security_model=mapped-xattr,id=nixos-config" \
        -display cocoa

# Boot the installed NixOS VM
[group('vm')]
boot-vm:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ ! -f "{{vm_disk}}" ]; then
        echo "No disk found. Run 'just create-disk' and install NixOS first."
        exit 1
    fi
    echo "Booting NixOS VM..."
    echo "  SSH: ssh -p {{ssh_port}} {{ssh_user}}@localhost"
    echo "  Press Ctrl-A X to exit QEMU"
    echo ""
    qemu-system-x86_64 \
        -m "{{vm_memory}}" \
        -smp "{{vm_cpus}}" \
        -drive "file={{vm_disk}},format=qcow2" \
        -nic "user,hostfwd=tcp::{{ssh_port}}-:22" \
        -virtfs "local,path=.,mount_tag=nixos-config,security_model=mapped-xattr,id=nixos-config" \
        -nographic

# Show VM status
[group('vm')]
status:
    @pgrep -f "qemu-system-x86_64.*{{vm_disk}}" > /dev/null && echo "VM is running" || echo "VM is not running"

# Kill all running QEMU processes
[group('vm')]
kill-vm:
    pkill qemu-system-x86_64 || true

# Bootstrap: copy config to VM and rebuild to enable 9p mount
[group('nix')]
bootstrap:
    scp -P {{ssh_port}} -r nixos/* {{ssh_user}}@localhost:/tmp/nixos-config/
    ssh -p {{ssh_port}} {{ssh_user}}@localhost "sudo cp -r /tmp/nixos-config/* /etc/nixos/ && sudo nixos-rebuild switch"

# Rebuild NixOS on the VM from the shared flake config
[group('nix')]
rebuild:
    ssh -p {{ssh_port}} {{ssh_user}}@localhost "sudo nixos-rebuild switch --flake /mnt/nixos-config#vm"

# Copy hardware-configuration.nix from VM to local repo
[group('nix')]
fetch-hw-config:
    scp -P {{ssh_port}} {{ssh_user}}@localhost:/etc/nixos/hardware-configuration.nix nixos/hardware-configuration.nix

# Format nix files
[group('nix')]
fmt:
    nix fmt

# Run flake checks
[group('nix')]
check:
    nix flake check
