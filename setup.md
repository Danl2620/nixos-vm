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

## Setting Up a New User

Once the VM is running, SSH in and create a new user:

### 1. Switch to root

```bash
sudo -i
```

### 2. Edit the NixOS configuration

```bash
nano /etc/nixos/configuration.nix
```

Add a new user block:

```nix
users.users.yourname = {
  isNormalUser = true;
  description = "Your Name";
  extraGroups = [ "wheel" "networkmanager" ];
  initialPassword = "changeme";
  openssh.authorizedKeys.keys = [
    # Optional: paste your public SSH key here
    # "ssh-ed25519 AAAA..."
  ];
};
```

### 3. Rebuild the system

```bash
sudo nixos-rebuild switch
```

### 4. Log in as the new user and change the password

```bash
su - yourname
passwd
```

### 5. (Optional) Disable the initial password

After setting a real password, remove `initialPassword` from the config and rebuild:

```bash
sudo nano /etc/nixos/configuration.nix
# Remove the initialPassword line
sudo nixos-rebuild switch
```

### 6. (Optional) Add your SSH key from the host

From the host machine:

```bash
just scp-to ~/.ssh/id_ed25519.pub
```

Then in the VM:

```bash
mkdir -p ~/.ssh
cat /tmp/id_ed25519.pub >> ~/.ssh/authorized_keys
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

Or add the key directly in `configuration.nix` (preferred NixOS way) as shown in step 2.

## Managing Configuration with the Shared Flake

The VM's NixOS configuration lives in this repository under `nixos/`. A 9p shared folder
mounts the repo at `/mnt/nixos-config` inside the VM, so edits on the host are instantly
visible in the VM.

### Initial setup (one-time, after first install)

1. Copy `hardware-configuration.nix` from the VM to the repo:

   ```bash
   just fetch-hw-config
   ```

2. Reboot the VM so the 9p mount is available:

   ```bash
   just kill-vm
   vm.sh boot-vm
   ```

3. Rebuild from the shared flake:

   ```bash
   just rebuild
   ```

   This runs `nixos-rebuild switch --flake /mnt/nixos-config#vm` on the VM.

### Day-to-day workflow

1. Edit files under `nixos/` on the host (e.g., add a module, change a setting)
2. Run `just rebuild` to apply changes to the VM
3. No SCP or git push needed — changes are shared instantly via 9p

### File layout

```
nixos/
  configuration.nix          # Main config (imports modules)
  hardware-configuration.nix  # From VM (just fetch-hw-config)
  modules/
    serial-console.nix        # Serial console for -nographic
    users.nix                 # User accounts
    ssh.nix                   # OpenSSH config
```

### Adding a new module

1. Create `nixos/modules/your-module.nix`:

   ```nix
   {
     # your NixOS options here
   }
   ```

2. Import it in `nixos/configuration.nix`:

   ```nix
   imports = [
     ./hardware-configuration.nix
     ./modules/serial-console.nix
     ./modules/users.nix
     ./modules/ssh.nix
     ./modules/your-module.nix
   ];
   ```

3. Apply: `just rebuild`
