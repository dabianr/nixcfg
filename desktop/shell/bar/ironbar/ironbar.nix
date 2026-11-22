{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.desktop.shell.bar.ironbar;
in {
  options.desktop.shell.bar.ironbar = {
    enable = lib.mkEnableOption "ironbar status bar";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      ironbar
      brightnessctl
      networkmanagerapplet
      pwvucontrol
      wireplumber
    ];
  };
}
