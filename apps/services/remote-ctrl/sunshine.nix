{
  config,
  lib,
  ...
}: let
  cfg = config.apps.services.remote-ctrl.sunshine;
in {
  options.apps.services.remote-ctrl.sunshine.enable = lib.mkEnableOption "Sunshine 串流服务端 (Moonlight)";

  config = lib.mkIf cfg.enable {
    services.sunshine = {
      enable = true;
      capSysAdmin = true;
    };

    # 只给 EasyTier 虚拟网访问, 不对 LAN/WAN 开放; 端口基于默认 47989
    networking.firewall.interfaces.easytier0 = {
      allowedTCPPorts = [47984 47989 47990 48010];
      allowedUDPPorts = [47998 47999 48000 48002 48010];
    };
  };
}
