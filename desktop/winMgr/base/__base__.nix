{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.desktop.winMgr.base;
in {
  imports = [
    ./polkit.nix
    ./xdg.nix
  ];

  options.desktop.winMgr.base.enable = lib.mkEnableOption "base";

  config = lib.mkIf cfg.enable {
    desktop.winMgr.base.polkit.enable = lib.mkDefault true;
    desktop.winMgr.base.xdg.enable = lib.mkDefault true;

    environment.systemPackages = with pkgs; [
      xauth
      wl-clipboard
      xwayland-satellite
    ];

    programs.uwsm.enable = true;

    environment.sessionVariables.NIXOS_OZONE_WL = "1";
    # target 没有 StopTimeoutSec; 会话收尾由 user manager 的默认停止超时兜底
    systemd.user.settings.Manager.DefaultTimeoutStopSec = 3;
  };
}
