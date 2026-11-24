{
  pkgs,
  username,
  lib,
  config,
  ...
}: let
  cfg = config.apps.services.remote-ctrl.vnc;
in {
  options.apps.services.remote-ctrl.vnc.enable = lib.mkEnableOption "wayvnc + novnc";

  config = lib.mkIf cfg.enable {
  environment.systemPackages = with pkgs; [
    wayvnc
    novnc
    wlr-randr
    #sunshine
  ];
  home-manager.users.${username} = {
    xdg.configFile = {
      "wayvnc/config" = {
        source = ./wayvnc;
      };
    };
  };
  };
}
