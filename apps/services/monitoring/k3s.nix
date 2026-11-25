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

    # 登录后再起: 用 timer 取代 oneshot + systemctl --no-block。
    # 后者虽然让 multi-user 先到, 但 k3s 的启动 job 仍挂在 boot 事务里
    # (实测 Startup finished 被拖到 14.4s), 而且登录瞬间与 k3s 抢 IO。
    systemd.services.k3s = {
      wantedBy = lib.mkForce [];
      wants = lib.mkForce ["firewall.service"];
      after = lib.mkForce ["firewall.service" "network.target"];
      # 模块默认 TimeoutStartSec=0: Type=notify 一旦卡住就永不失败、也不重启;
      # KillMode=process 会留下 containerd-shim, 关机时改成 mixed 并在 15s 后强杀
      serviceConfig = {
        TimeoutStartSec = lib.mkForce "10min";
        TimeoutStopSec = lib.mkForce "15s";
        KillMode = lib.mkForce "mixed";
      };
    };
    systemd.timers.k3s = {
      wantedBy = ["timers.target"];
      timerConfig.OnBootSec = "2min";
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
