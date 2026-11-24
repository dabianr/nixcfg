{
  config,
  lib,
  pkgs,
  username,
  ...
}: let
  cfg = config.apps.services.ai.opencode;
  opencodeWrapped = import ../wrap.nix {inherit config pkgs;} "opencode" pkgs.opencode "opencode";
in {
  options.apps.services.ai.opencode.enable = lib.mkEnableOption "opencode CLI";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      opencodeWrapped
    ];

    home-manager.users.${username} = {
      xdg.configFile."opencode/opencode.json" = {
        source = ./opencode.json;
      };
    };
  };
}
