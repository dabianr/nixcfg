{
  config,
  lib,
  username,
  ...
}: let
  cfg = config.apps.services.monitoring.k3s;
in {
  options.apps.services.monitoring.k3s.enable = lib.mkEnableOption "single-node k3s server";

  config = lib.mkIf cfg.enable {
    users.groups.k3s = {};
    users.users.${username}.extraGroups = ["k3s"];

    services.k3s = {
      enable = true;
      role = "server";
      # kubeconfig 由 k3s 自己写, chmod 会被下次启动覆盖, 所以用它的 flag 定 mode/group
      extraFlags = [
        "--write-kubeconfig-mode=640"
        "--write-kubeconfig-group=k3s"
      ];
    };

    # 改到登录后启动
    systemd.services.k3s.wantedBy = lib.mkForce [];
    systemd.services.k3s-background = {
      description = "Start k3s in the background (do not block boot)";
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${config.systemd.package}/bin/systemctl --no-block start k3s.service";
      };
    };

    # /proc/net -> /proc/self/net, 所以 node-exporter 是 hostNetwork
    networking.firewall = {
      allowedTCPPorts = [6443 10250];
      allowedUDPPorts = [8472];
      extraInputRules = ''
        iifname "cni0" tcp dport 9100 accept
      '';
    };
  };
}
