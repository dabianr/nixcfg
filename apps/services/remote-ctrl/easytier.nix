{
  config,
  lib,
  ...
}: let
  # 10.144.144.0/24 是 EasyTier 默认虚拟网段, 每台机器固定一个地址
  ipv4 = {
    pc = "10.144.144.1/24";
    lap = "10.144.144.2/24";
    hjl = "10.144.144.3/24";
  };
in {
  options.apps.services.remote-ctrl.easytier.enable = lib.mkEnableOption "EasyTier 组网 (NAT 穿透 + 共享节点中继)";

  config = lib.mkIf config.apps.services.remote-ctrl.easytier.enable {
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
      '';
    };

    services.easytier = {
      enable = true;
      instances.default = {
        settings = {
          hostname = config.networking.hostName;
          ipv4 = lib.attrByPath [config.networking.hostName] null ipv4;
          # 双方都没有公网服务器: 用社区共享节点做发现, P2P 失败时兜底中继。
          # 节点失效就替换, 所有机器保持同一份列表。
          peers = [
            # 2026-11 实测可用; 用 IP 不用域名: mihomo fake-ip 会把域名解析成 28.0.0.x 导致连不上
            "tcp://107.150.25.187:11010"
            "udp://107.150.25.187:11010"
          ];
        };
        # 固定 TUN 名字, 防火墙规则和排障都认它
        extraSettings.flags.dev_name = "easytier0";
        environmentFiles = [config.sops.templates."easytier-env".path];
      };
    };

    # 11010 用于直连和 NAT 打洞后的入站
    networking.firewall = {
      allowedUDPPorts = [11010];
      allowedTCPPorts = [11010];
      # novnc
      interfaces.easytier0.allowedTCPPorts = [6080];
    };

    systemd.services."easytier-default" = {
      wants = ["sops-install-secrets.service"];
      after = ["sops-install-secrets.service"];
    };
  };
}
