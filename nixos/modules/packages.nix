{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # version control
    git

    # editors
    vim

    # shell / terminal
    tmux
    htop

    # search / navigation
    ripgrep
    fd
    tree

    # file viewing / processing
    bat
    jq
    less

    # network
    curl
    wget

    # archives
    unzip
    gnutar

    # misc
    just
  ];
}
