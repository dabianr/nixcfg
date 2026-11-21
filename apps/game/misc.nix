{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.apps.game.misc;
in {
  options.apps.game.misc.enable = lib.mkEnableOption "HMCL (Minecraft launcher)";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      hmcl
    ];
  };
}
