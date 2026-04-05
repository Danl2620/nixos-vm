# NixOS VM Setup Guide

## Boot the Installer

```bash
nix develop
vm.sh boot-installer
```

## Install NixOS

Once booted into the installer:

### 1. Set a password (for SSH access from host)

```bash
passwd
```

### 2. Partition the disk

```bash
fdisk /dev/sda
# Type: n → p → 1 → Enter → Enter → w
```

### 3. Format and mount

```bash
mkfs.ext4 /dev/sda1
mount /dev/sda1 /mnt
```

### 4. Generate config

```bash
nixos-generate-config --root /mnt
```

### 5. Edit the configuration

```bash
nano /mnt/etc/nixos/configuration.nix
```

Add/ensure these settings:

```nix
boot.loader.grub.device = "/dev/sda";

# Serial console (required for boot-vm's -nographic mode)
boot.kernelParams = [ "console=ttyS0" ];
boot.loader.grub.extraConfig = ''
  serial --unit=0 --speed=115200
  terminal_input serial console
  terminal_output serial console
'';
systemd.services."serial-getty@ttyS0".enable = true;

# SSH access
services.openssh.enable = true;

# A user account (or set root password)
users.users.nixos = {
  isNormalUser = true;
  extraGroups = [ "wheel" ];
  initialPassword = "nixos";
};
```

### 6. Install

```bash
nixos-install
# Set the root password when prompted
```

### 7. Shut down

```bash
shutdown -h now
```

## Boot the Installed VM

```bash
vm.sh boot-vm
```

SSH in from the host:

```bash
just ssh
```

Or manually:

```bash
ssh -p 2223 nixos@localhost
```

Exit QEMU: `Ctrl-A X`
