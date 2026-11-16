{
  config,
  lib,
  pkgs,
  inputs,
  username,
  ...
}: let
  cfg = config.modules.virtual.droidloom;
in {
  imports = [inputs.droidloom.nixosModules.default];

  options.modules.virtual.droidloom.enable = lib.mkEnableOption "DroidLoom (Android 容器, 实验性)";

  # 上游只发布 Arch 包, 由 inputs.droidloom 重打包 host 并生成 cell 配置。
  # 启用后首次构建需编译 Rust host 并拉取约 1GB Android 镜像, 较慢。
  config = lib.mkIf cfg.enable {
    services.droidloom = {
      enable = true;
      user = username;
      uid = config.users.users.${username}.uid;
      manageSubIds = true;
    };

    # DroidLoom 的 nft input 规则对 dlh1000 只放行 ADB(:5555) 的 established
    # 回包, 其余 cell→host 新连接全部 drop; 所以 cell 不能直连主机代理。
    #
    # 反过来, mihomo 的 TUN auto-route 规则 "not from all iif lo lookup 2022"
    # 会把 cell 的转发流量也抓进 TUN, 而 gvisor 处理不了非本机源 TCP, 结果
    # cell 里除 :53(DNS, 有单独直连规则) 外的 TCP 全部挂起。用更高优先级的
    # 规则把 cell 子网放回 main 表, 让它继续走主机 NAT 直连。
    # systemd.services.mihomo = lib.mkIf config.apps.services.proxy.mihomo.enable {
    #   postStart = ''
    #     ${pkgs.iproute2}/bin/ip rule add from 10.177.0.0/30 lookup main pref 8999 2>/dev/null || true
    #   '';
    #   preStop = ''
    #     ${pkgs.iproute2}/bin/ip rule del from 10.177.0.0/30 lookup main pref 8999 2>/dev/null || true
    #   '';
    # };

    systemd.user.services.droidloom-adb-reverse = lib.mkIf config.apps.services.proxy.mihomo.enable {
      description = "Reverse-tunnel host mihomo into the DroidLoom cell";
      after = ["droidloom.service"];
      wantedBy = ["droidloom.service"];
      unitConfig.ConditionUser = username;
      serviceConfig = {
        Type = "oneshot";
        TimeoutStartSec = "240s";
        ExecStart = pkgs.writeShellScript "droidloom-adb-reverse" ''
          set -eu
          export PATH=${pkgs.coreutils}/bin:${pkgs.android-tools}/bin:$PATH
          i=0
          while [ "$i" -lt 60 ]; do
            if adb -s device:droidloom get-state >/dev/null 2>&1; then break; fi
            i=$((i + 1))
            sleep 2
          done
          adb -s device:droidloom reverse --remove tcp:7897 >/dev/null 2>&1 || true
          adb -s device:droidloom reverse --remove tcp:55099 >/dev/null 2>&1 || true
          adb -s device:droidloom reverse tcp:55099 tcp:7897
          adb -s device:droidloom shell settings put global http_proxy 127.0.0.1:55099
        '';
      };# 55099为cell侧 7897主机侧
    };
  };
}
