{username, lib, ...}: {
  time.timeZone = "Asia/Shanghai";
  i18n.defaultLocale = "zh_CN.UTF-8";

  nixpkgs.config = {
    allowUnfree = true;
    problems.handlers = {
      "gtk+".broken = "warn"; #TODO
    };
  };
    
    
  boot.zfs.forceImportRoot = false; # 无 ZFS, 按 26.11 推荐关闭强制导入

  # zram
  boot.kernel.sysctl = {
    "vm.swappiness" = 180;
    "vm.page-cluster" = 0;
    "vm.watermark_boost_factor" = 0;
    "vm.watermark_scale_factor" = 125;
  };

  # 大构建时让出 CPU/IO, 保持桌面响应
  nix.daemonCPUSchedPolicy = "batch";
  nix.daemonIOSchedClass = "idle";

  # services.logind.settings.Login = {
  #     KillUserProcesses = true;
  # };

  nix.settings = {
    # 优先级由各缓存自己的 /nix-cache-info 决定(nixos.org=40), 这里只按顺序打破平手;
    # 官方的 ?priority= 查询参数并不存在, 写了也只会被当成 URL 的一部分发给对方。
    substituters = [
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
      "https://cache.nixos.org/"
    ];
    experimental-features = ["nix-command" "flakes"];
    max-jobs = "auto";
    cores = 0;
    auto-optimise-store = true;
  };

  nix.optimise = {
    automatic = true;
    dates = ["03:45"];
    randomizedDelaySec = "1h";
  };

  nix.gc = {
    automatic = true;
    dates = "03:15";
    options = "--delete-older-than 7d";
    # 错过计划时间(关机)时,开机延迟随机 0-1h 补跑,避免阻塞启动
    randomizedDelaySec = "1h";
  };

  # 关机兜底: 单个 unit 停不下来最多等 15s, 整个关机流程卡死则 90s 后强制重启
  systemd.settings.Manager = {
    DefaultTimeoutStopSec = "15s";
    ShutdownWatchdogSec = "90s";
  };

  # resolvconf 每次 resolv.conf 变更都会 try-restart nscd 清 DNS 缓存; 开机时
  # NM 连发几次地址变化就会连拉 5 次, 撞上默认 start-limit 留下 failed/degraded。
  # 这类重启是正常行为而非崩溃循环, 对该 unit 关掉限流即可
  systemd.services.nscd.startLimitIntervalSec = 0;

  # 后台 GC/优化让出 CPU 与 IO, 避免开机补跑时与登录后的交互抢资源
  systemd.services = {
    nix-gc.serviceConfig = {
      Nice = 19;
      IOSchedulingClass = "idle";
    };
    nix-optimise.serviceConfig = {
      Nice = 19;
      IOSchedulingClass = "idle";
    };
  };

  # programs.fish 会 mkDefault 打开 man 索引缓存, 使每次开机都跑一遍 mandb
  # 扫描全部 man 页(实测 3.2s / 读盘 150MB); 文档输出已关, 缓存也不再生成
  documentation.man.cache = {
    enable = lib.mkForce false;
    generateAtRuntime = lib.mkForce false;
  };

  documentation.enable = false;

  security.sudo = {
    enable = true;

    extraConfig = ''
      Defaults env_keep += "http_proxy https_proxy ftp_proxy rsync_proxy all_proxy"
      Defaults env_keep += "HTTP_PROXY HTTPS_PROXY FTP_PROXY RSYNC_PROXY ALL_PROXY"
    '';

    extraRules = [
      {
        users = ["${username}"];
        commands = [
          {
            command = "/run/current-system/sw/bin/podman";
            options = ["NOPASSWD"];
          }
        ];
      }
    ];
  };
}
