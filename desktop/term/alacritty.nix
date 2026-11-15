{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.desktop.term.alacritty;
in {
  options.desktop.term.alacritty.enable = lib.mkEnableOption "alacritty terminal";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      alacritty
    ];
  };
}
