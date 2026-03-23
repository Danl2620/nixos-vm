{
  description = "NixOS QEMU VM development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};

      # VM configuration
      vmName = "nixos-vm";
      vmDisk = "${vmName}.qcow2";
      vmDiskSize = "20G";
      vmMemory = "2048";
      vmCpus = "2";
      sshPort = "2222";
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          qemu
        ];

        shellHook = ''
          echo "NixOS QEMU VM environment"
          echo ""
          echo "Commands:"
          echo "  create-disk    - Create a ${vmDiskSize} virtual disk"
          echo "  fetch-iso      - Download the latest NixOS minimal ISO"
          echo "  boot-installer - Boot the NixOS installer ISO"
          echo "  boot-vm        - Boot the installed NixOS VM"
          echo ""

          create-disk() {
            if [ -f "${vmDisk}" ]; then
              echo "Disk ${vmDisk} already exists. Delete it first to recreate."
              return 1
            fi
            qemu-img create -f qcow2 "${vmDisk}" "${vmDiskSize}"
            echo "Created ${vmDisk} (${vmDiskSize})"
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
              echo "No ISO found. Run 'fetch-iso' first."
              return 1
            fi
            if [ ! -f "${vmDisk}" ]; then
              echo "No disk found. Run 'create-disk' first."
              return 1
            fi
            echo "Booting NixOS installer..."
            echo "  SSH will be available on localhost:${sshPort} once you enable sshd"
            echo "  Press Ctrl-A X to exit QEMU"
            echo ""
            qemu-system-x86_64 \
              -m ${vmMemory} \
              -smp ${vmCpus} \
              -cdrom "$iso_file" \
              -boot d \
              -drive file="${vmDisk}",format=qcow2 \
              -nic user,hostfwd=tcp::${sshPort}-:22 \
              -nographic
          }

          boot-vm() {
            if [ ! -f "${vmDisk}" ]; then
              echo "No disk found. Run 'create-disk' and install NixOS first."
              return 1
            fi
            echo "Booting NixOS VM..."
            echo "  SSH: ssh -p ${sshPort} root@localhost"
            echo "  Press Ctrl-A X to exit QEMU"
            echo ""
            qemu-system-x86_64 \
              -m ${vmMemory} \
              -smp ${vmCpus} \
              -drive file="${vmDisk}",format=qcow2 \
              -nic user,hostfwd=tcp::${sshPort}-:22 \
              -nographic
          }
        '';
      };
    };
}
