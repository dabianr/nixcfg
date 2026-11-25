{
  config,
  lib,
  ...
}: let
  cfg = config.apps.services.remote.cloudflared;
in {
  options.apps.services.remote.cloudflared = {
    enable = lib.mkEnableOption "shared cloudflared tunnel";

    ingress = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
      description = "cloudflared ingress rules: hostname -> origin URL";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.cloudflared-sh-tunnel.sopsFile = config.secrets.path + "/token.yaml";

    services.cloudflared = {
      enable = true;
      tunnels."sh-tunnel" = {
        credentialsFile = config.sops.secrets.cloudflared-sh-tunnel.path;
        # TUN, QUIC/UDP 经代理节点常被拖到超时 http2 QUIC/UDP 受限时的开
        protocol = "http2";
        inherit (cfg) ingress;
        default = "http_status:404";
      };
    };

    # 改为开机 20s 后由 timer 拉起, 失败按 5s 重试
    systemd.services."cloudflared-tunnel-sh-tunnel" = {
      wantedBy = lib.mkForce [];
      wants = lib.mkForce ["network.target"];
      after = lib.mkForce ["network.target"];
      serviceConfig = {
        RestartSec = lib.mkForce "5s";
        # 隧道已注册连接时 SIGTERM 偶尔不退, 5s 后强杀
        TimeoutStopSec = lib.mkForce "5s";
      };
    };
    systemd.timers."cloudflared-tunnel-sh-tunnel" = {
      wantedBy = ["timers.target"];
      timerConfig.OnBootSec = "20s";
    };
  };
}
