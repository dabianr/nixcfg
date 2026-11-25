{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.apps.services.remote.cloudflared;
  unit = "cloudflared-tunnel-sh-tunnel";
  health = "${unit}-health";
  metricsAddr = "127.0.0.1:20241";
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
        # 直连优先用 QUIC(UDP 7844), 不行再退 HTTP/2(TCP 7844):
        protocol = "auto";
        inherit (cfg) ingress;
        default = "http_status:404";
      };
    };

    # 改为开机 20s 后由 timer 拉起, 失败按 5s 重试
    systemd.services.${unit} = {
      wantedBy = lib.mkForce [];
      wants = lib.mkForce ["network.target"];
      after = lib.mkForce ["network.target"];
      serviceConfig = {
        RestartSec = lib.mkForce "5s";
        # 隧道已注册连接时 SIGTERM 偶尔不退, 5s 后强杀
        TimeoutStopSec = lib.mkForce "5s";
      };
      # 不指定时 cloudflared 会自己顺延挑端口(20241 被占就用 20242), 健康检查会找不到它
      environment.TUNNEL_METRICS = metricsAddr;
    };
    systemd.timers.${unit} = {
      wantedBy = ["timers.target"];
      timerConfig.OnBootSec = "20s";
    };


    systemd.services.${health} = {
      script = ''
        ${lib.getExe pkgs.curl} -sf --max-time 5 http://${metricsAddr}/ready && exit 0
        ${config.systemd.package}/bin/systemctl --no-block try-restart ${unit}
      '';
      serviceConfig.Type = "oneshot";
    };
    systemd.timers.${health} = {
      wantedBy = ["timers.target"];
      timerConfig = {
        OnBootSec = "3min";
        OnUnitActiveSec = "3min";
      };
    };
  };
}
