{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./modules/serial-console.nix
    ./modules/users.nix
    ./modules/ssh.nix
  ];

  boot.loader.grub.device = "/dev/sda";

  # Mount the host's 9p shared folder
  fileSystems."/mnt/nixos-config" = {
    device = "nixos-config";
    fsType = "9p";
    options = [
      "trans=virtio"
      "version=9p2000.L"
      "nofail"
    ];
  };

  # Allow the VM to evaluate flakes
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  system.stateVersion = "24.11";
}
