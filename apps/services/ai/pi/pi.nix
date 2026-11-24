{
  config,
  lib,
  pkgs,
  username,
  ...
}: let
  cfg = config.apps.services.ai.pi;
  piWrapped = import ../wrap.nix {inherit config pkgs;} "pi" pkgs.pi-coding-agent "pi";
in {
  options.apps.services.ai.pi.enable = lib.mkEnableOption "pi-coding-agent CLI";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      piWrapped
    ];

    home-manager.users.${username} = {
      home.file.".pi/agent/settings.json" = {
        source = ./settings.json;
      };
    };
  };
}
