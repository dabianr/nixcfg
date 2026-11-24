{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.apps.services.remote-ctrl.moonlight;
in {
  options.apps.services.remote-ctrl.moonlight.enable = lib.mkEnableOption "Moonlight 串流客户端";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [pkgs.moonlight-qt];
  };
}
