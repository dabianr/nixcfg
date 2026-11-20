{
  config,
  lib,
  pkgs,
  username,
  inputs,
  ...
}: let
  cfg = config.apps.services.ai.herdr;
  pkg = inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default;
in {
  options.apps.services.ai.herdr.enable = lib.mkEnableOption "herdr (terminal workspace manager for AI coding agents)";

  config = lib.mkIf cfg.enable {
    home-manager.users.${username}.home.packages = [pkg];
  };
}
