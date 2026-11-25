{
  config,
  lib,
  ...
}: let
  cfg = config.apps.services.remote-ctrl.easytier;
  env = [config.sops.templates."easytier-env".path];
  entry = cfg.relayDomain != null;
in {
  options.apps.services.remote-ctrl.easytier = {
    enable = lib.mkEnableOption "EasyTier 组网";
    ipv4 = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "本机虚拟 IP";
    };
    peers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "启动时连接的对端 (入口机自动指到本机 gw)";
    };
    relayDomain = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "入口机域名; 设置后额外起一个 gw 中继实例, 打洞才不会把 ws 入口当直连";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      boot.kernelModules = ["tun"];

      # ─── secret ───────────────────────
      sops.secrets.easytier_network_name.sopsFile = config.secrets.path + "/token.yaml";
      sops.secrets.easytier_network_secret.sopsFile = config.secrets.path + "/token.yaml";
      sops.templates."easytier-env".content = ''
        ET_NETWORK_NAME=${config.sops.placeholder.easytier_network_name}
        ET_NETWORK_SECRET=${config.sops.placeholder.easytier_network_secret}
      '';

      # 原来的 network-online 会把 NetworkManager-wait-online 拖进 boot 关键链;
      # sops-install-secrets.service 在本机不存在(secrets 在 initrd 激活阶段写入)。
      systemd.services = lib.genAttrs (["easytier-default"] ++ lib.optional entry "easytier-gw") (_: {
        wants = lib.mkForce ["network.target" "nss-lookup.target"];
        after = lib.mkForce ["network.target" "nss-lookup.target"];
      });

      # ─── instance ───────────────────────
      services.easytier = {
        enable = true;
        instances =
          {
            # 节点, 入口机 peers 指到本地 gw
            default = {
              settings = {
                hostname = config.networking.hostName;
                ipv4 = cfg.ipv4;
                listeners = ["tcp://0.0.0.0:11010" "udp://0.0.0.0:11010"];
                peers =
                  if entry
                  then ["tcp://127.0.0.1:11020" "udp://127.0.0.1:11020"]
                  else cfg.peers;
              };
              extraSettings.flags = {
                dev_name = "easytier0";
                need_p2p = true;
              };
              extraArgs = ["--bind-device" "false"];
              environmentFiles = env;
            };
          }
          // lib.optionalAttrs entry {
            # gateway: 纯监听
            gw = {
              settings = {
                hostname = "${config.networking.hostName}-gw";
                listeners = ["tcp://127.0.0.1:11020" "udp://127.0.0.1:11020" "ws://127.0.0.1:11021"];
              };
              extraSettings.flags = {
                no_tun = true; 
                private_mode = true; # 只服务 env 中声明的网络
              };
              extraArgs = ["--rpc-portal" "127.0.0.1:15889"];
              environmentFiles = env;
            };
          };
      };

      # ─── firewall ───────────────────────
      networking.firewall = {
        allowedUDPPorts = [11010];
        allowedTCPPorts = [11010];
        interfaces.easytier0.allowedTCPPorts = [6080]; # novnc
      };
    })

    # ─── tunnel ───────────────────────
    (lib.mkIf (cfg.enable && entry) {
      apps.services.cloudflared = {
        enable = true;
        ingress."${cfg.relayDomain}" = "http://127.0.0.1:11021";
      };
    })
  ];
}
