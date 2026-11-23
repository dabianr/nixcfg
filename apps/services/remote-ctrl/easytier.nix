{
  config,
  lib,
  ...
}: let
  cfg = config.apps.services.remote-ctrl.easytier;
in {
  options.apps.services.remote-ctrl.easytier = {
    enable = lib.mkEnableOption "EasyTier 组网";
    ipv4 = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "本机虚拟 IP, 如 10.144.144.1/24; 留空则只转发不建 TUN";
      example = "10.144.144.1/24";
    };
    peers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "启动时连接的对端, 如公共节点 tcp:///udp:// 或入口机 wss://<relayDomain>";
    };
    relayDomain = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "入口机把这个节点作为 Cloudflare Tunnel 公网入口的域名";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      boot.kernelModules = ["tun"];

      # 网络名和密钥都在 token.yaml 里, 渲染成 env 文件给 EasyTier 用, 不进 nix store
      sops.secrets.easytier_network_name = {
        sopsFile = config.secrets.path + "/token.yaml";
      };
      sops.secrets.easytier_network_secret = {
        sopsFile = config.secrets.path + "/token.yaml";
      };
      sops.templates."easytier-env" = {
        content = ''
          ET_NETWORK_NAME=${config.sops.placeholder.easytier_network_name}
          ET_NETWORK_SECRET=${config.sops.placeholder.easytier_network_secret}
          # 公网入口只服务本网络
          ET_PRIVATE_MODE=true
        '';
      };

      services.easytier = {
        enable = true;
        instances.default = {
          settings = {
            hostname = config.networking.hostName;
            ipv4 = cfg.ipv4;
            # 11010 所有网卡监听: NAT 打洞后对端从物理网卡进来
            # 11011 只给入口机的 cloudflared 用, 非入口机不开
            listeners =
              [
                "tcp://0.0.0.0:11010"
                "udp://0.0.0.0:11010"
              ]
              ++ lib.optional (cfg.relayDomain != null) "ws://127.0.0.1:11011";
            peers = cfg.peers;
          };
          # 固定 TUN 名字, 防火墙规则和排障都认它
          extraSettings.flags.dev_name = "easytier0";
          # 关键: 不把出站 socket 绑到物理网卡, 否则多网卡并发 dial 时
          # 物理网卡那条直连 Cloudflare 会被 RST 并抢走连接 (issue #646/#1629)
          extraArgs = ["--bind-device" "false"];
          environmentFiles = [config.sops.templates."easytier-env".path];
        };
      };

      # 11010 用于直连和 NAT 打洞后的入站; 11011 只走 cloudflared 本地回环
      networking.firewall = {
        allowedUDPPorts = [11010];
        allowedTCPPorts = [11010];
        # novnc
        interfaces.easytier0.allowedTCPPorts = [6080];
      };

      # 等 sops 渲染完 env 文件再启动
      systemd.services."easytier-default" = {
        wants = ["sops-install-secrets.service"];
        after = ["sops-install-secrets.service"];
      };
    })

    (lib.mkIf (cfg.enable && cfg.relayDomain != null) {
      sops.secrets.cloudflared-sh-tunnel = {
        sopsFile = config.secrets.path + "/token.yaml";
      };

      services.cloudflared = {
        enable = true;
        tunnels."sh-tunnel" = {
          credentialsFile = config.sops.secrets.cloudflared-sh-tunnel.path;
          ingress."${cfg.relayDomain}" = "http://127.0.0.1:11011";
          default = "http_status:404";
        };
      };
    })
  ];
}
