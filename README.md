# NixOS QEMU VM

A nix flake that provides a dev shell with QEMU and helper commands for running a NixOS VM.

## Quick Start

```bash
# Enter the dev shell (installs QEMU)
nix develop

# Create a 20G virtual disk
vm.sh create-disk

# Download the NixOS 24.11 minimal ISO
vm.sh fetch-iso

# Boot the installer (console mode)
vm.sh boot-installer
```

## Installing NixOS

Once booted into the installer:

1. Partition the disk:
   ```bash
   fdisk /dev/sda
   # n -> p -> 1 -> Enter -> Enter -> w  (create partition, write)
   ```

2. Format and mount:
   ```bash
   mkfs.ext4 /dev/sda1
   mount /dev/sda1 /mnt
   ```

3. Generate and edit config:
   ```bash
   nixos-generate-config --root /mnt
   nano /mnt/etc/nixos/configuration.nix
   ```

4. In `configuration.nix`, ensure these are set:
   ```nix
   boot.loader.grub.device = "/dev/sda";

   # For console access (required for -nographic mode)
   boot.kernelParams = [ "console=ttyS0" ];
   systemd.services."getty@ttyS0".enable = true;

   # Optional: enable SSH
   services.openssh.enable = true;
   ```

5. Install and reboot:
   ```bash
   nixos-install
   shutdown -h now
   ```

## Booting the Installed VM

```bash
nix develop
vm.sh boot-vm
```

- SSH: `ssh -p 2222 root@localhost`
- Exit QEMU: `Ctrl-A X`

## VM Settings

Defaults configured in `vm.sh`:

| Setting   | Value |
|-----------|-------|
| Disk size | 20G   |
| Memory    | 2048M |
| CPUs      | 2     |
| SSH port  | 2222  |
