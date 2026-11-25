{
  config,
  lib,
  ...
}: let
  cfg = config.apps.services.cloudflared;
in {
  options.apps.services.cloudflared = {
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
        # 本机出网走 mihomo TUN, QUIC(UDP) 经代理节点常被拖到超时;
        # http2 走 TCP 更稳(模块注释里点名这是 QUIC/UDP 受限时的开关)
        protocol = "http2";
        inherit (cfg) ingress;
        default = "http_status:404";
      };
    };

    # 隧道需要 DNS 就绪, 但不应把 boot 卡在 network-online 上:
    # 改为开机 20s 后由 timer 拉起(10s 时 mihomo 的 DNS 还在 SERVFAIL), 失败按 5s 重试
    systemd.services."cloudflared-tunnel-sh-tunnel" = {
      wantedBy = lib.mkForce [];
      wants = lib.mkForce ["network.target"];
      after = lib.mkForce ["network.target"];
      serviceConfig.RestartSec = lib.mkForce "5s";
    };
    systemd.timers."cloudflared-tunnel-sh-tunnel" = {
      wantedBy = ["timers.target"];
      timerConfig.OnBootSec = "20s";
    };
  };
}
