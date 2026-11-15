{
  config,
  lib,
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
  };
}
