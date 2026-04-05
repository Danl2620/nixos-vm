#!/usr/bin/env bash
set -euo pipefail

# VM configuration
VM_NAME="nixos-vm"
VM_DISK="${VM_NAME}.qcow2"
VM_DISK_SIZE="20G"
VM_MEMORY="2048"
VM_CPUS="2"
SSH_PORT="2223"

create-disk() {
	if [ -f "$VM_DISK" ]; then
		echo "Disk $VM_DISK already exists. Delete it first to recreate."
		return 1
	fi
	qemu-img create -f qcow2 "$VM_DISK" "$VM_DISK_SIZE"
	echo "Created $VM_DISK ($VM_DISK_SIZE)"
}

fetch-iso() {
	local iso_url="https://channels.nixos.org/nixos-24.11/latest-nixos-minimal-x86_64-linux.iso"
	local iso_file="nixos-minimal.iso"
	if [ -f "$iso_file" ]; then
		echo "$iso_file already exists. Delete it to re-download."
		return 1
	fi
	echo "Downloading NixOS minimal ISO..."
	curl -L -o "$iso_file" "$iso_url"
	echo "Downloaded $iso_file"
}

boot-installer() {
	local iso_file="nixos-minimal.iso"
	if [ ! -f "$iso_file" ]; then
		echo "No ISO found. Run '$0 fetch-iso' first."
		return 1
	fi
	if [ ! -f "$VM_DISK" ]; then
		echo "No disk found. Run '$0 create-disk' first."
		return 1
	fi
	echo "Booting NixOS installer (graphical window)..."
	echo "  SSH will be available on localhost:$SSH_PORT once you set a password"
	echo "  Close the QEMU window or use the monitor to quit"
	echo ""
	qemu-system-x86_64 \
		-m "$VM_MEMORY" \
		-smp "$VM_CPUS" \
		-cdrom "$iso_file" \
		-boot d \
		-drive "file=$VM_DISK,format=qcow2" \
		-nic "user,hostfwd=tcp::${SSH_PORT}-:22" \
		-display cocoa
}

boot-vm() {
	if [ ! -f "$VM_DISK" ]; then
		echo "No disk found. Run '$0 create-disk' and install NixOS first."
		return 1
	fi
	echo "Booting NixOS VM..."
	echo "  SSH: ssh -p $SSH_PORT root@localhost"
	echo "  Press Ctrl-A X to exit QEMU"
	echo ""
	qemu-system-x86_64 \
		-m "$VM_MEMORY" \
		-smp "$VM_CPUS" \
		-drive "file=$VM_DISK,format=qcow2" \
		-nic "user,hostfwd=tcp::${SSH_PORT}-:22" \
		-nographic
}

usage() {
	echo "Usage: $0 <command>"
	echo ""
	echo "Commands:"
	echo "  create-disk    - Create a $VM_DISK_SIZE virtual disk"
	echo "  fetch-iso      - Download the latest NixOS minimal ISO"
	echo "  boot-installer - Boot the NixOS installer ISO"
	echo "  boot-vm        - Boot the installed NixOS VM"
}

case "${1:-}" in
create-disk) create-disk ;;
fetch-iso) fetch-iso ;;
boot-installer) boot-installer ;;
boot-vm) boot-vm ;;
*) usage ;;
esac
