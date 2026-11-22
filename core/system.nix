{username, ...}: {
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
