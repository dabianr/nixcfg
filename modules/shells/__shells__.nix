{
  config,
  lib,
  pkgs,
  username,
  ...
}: {
  options.modules.shells.enable = lib.mkEnableOption "shells";

  imports = [
    # ./bash/bash.nix
    ./fish/fish.nix
    ./zsh/zsh.nix
  ];

  config = lib.mkIf config.modules.shells.enable {
    users.defaultUserShell = pkgs.fish;
    # users.users.${username}.shell = pkgs.fish;

    home-manager.users.${username}.home.sessionPath = ["/home/${username}/.local/bin"];

    # ───── shell toolkits ─────────────────────────
    environment.systemPackages = with pkgs; [
      ripgrep
      fd
      fzf
      bat
      tree
      wget
      curl
      pciutils
      # vim
      file
    ];
  };
}
