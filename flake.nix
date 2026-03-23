{
  description = "NixOS QEMU VM development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      git-hooks,
    }:
    let
      system = "x86_64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};

      preCommitCheck = git-hooks.lib.${system}.run {
        src = ./.;
        hooks = {
          nixfmt.enable = true;
          shellcheck.enable = true;
          shfmt.enable = true;
        };
      };
    in
    {
      checks.${system} = {
        pre-commit-check = preCommitCheck;
      };

      formatter.${system} = pkgs.nixfmt;

      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          qemu
        ];

        buildInputs = preCommitCheck.enabledPackages;

        shellHook = ''
          ${preCommitCheck.shellHook}
          export PATH="${toString ./.}:$PATH"
          echo "NixOS QEMU VM environment"
          echo ""
          echo "Usage: vm.sh <command>"
          echo ""
          echo "Commands:"
          echo "  vm.sh create-disk    - Create a virtual disk"
          echo "  vm.sh fetch-iso      - Download the latest NixOS minimal ISO"
          echo "  vm.sh boot-installer - Boot the NixOS installer ISO"
          echo "  vm.sh boot-vm        - Boot the installed NixOS VM"
          echo ""
        '';
      };
    };
}
