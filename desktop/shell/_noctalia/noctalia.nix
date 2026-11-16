{
  config,
  lib,
  pkgs,
  username,
  ...
}: let
  cfg = config.desktop.shell._noctalia;

  # 上游“当前连接”卡片是单开关: 任何连接在时按钮只做 disconnect,
  # activateWiredConnection() 只在完全没连接时才会被调用, 所以 wifi 连着时
  # 无法重新拉起有线, 必须先断 wifi。补丁改成: 当前不是有线且有已保存的
  # 有线配置时, 插头按钮直接激活有线, 不需要先断 wifi。
  noctaliaPatched = pkgs.noctalia.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      patch -p1 --batch --fuzz=0 < ${./network-tab.patch}
    '';
  });
in {
  options.desktop.shell._noctalia.enable = lib.mkEnableOption "noctalia shell (bar, launcher, wallpaper, lock, notif)";

  config = lib.mkIf cfg.enable {
    programs.noctalia = {
      enable = true;
      package = noctaliaPatched;
    };

    services = lib.mkDefault {
      upower.enable = true;
      power-profiles-daemon.enable = true;
    };
    home-manager.users.${username} = {
      xdg.configFile."noctalia" = {
        force = true;
        recursive = true;
        source = ./config;
      };
    };
  };
}
