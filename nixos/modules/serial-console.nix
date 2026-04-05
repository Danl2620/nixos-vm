{
  boot.kernelParams = [ "console=ttyS0" ];

  boot.loader.grub.extraConfig = ''
    serial --unit=0 --speed=115200
    terminal_input serial console
    terminal_output serial console
  '';

  systemd.services."serial-getty@ttyS0".enable = true;
}
