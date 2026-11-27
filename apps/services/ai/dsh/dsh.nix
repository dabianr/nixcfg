{
  config,
  lib,
  pkgs,
  username,
  inputs,
  ...
}: let
  cfg = config.apps.services.ai.dsh;
  pkg = inputs.deepseek-harness.packages.${pkgs.stdenv.hostPlatform.system}.dsh;
in {
  options.apps.services.ai.dsh.enable = lib.mkEnableOption "dsh (DeepSeek Harness CLI)";

  config = lib.mkIf cfg.enable {
    home-manager.users.${username}.home.packages = [pkg];
  };
}
