{
  config,
  lib,
  ...
}: let
  cfg = config.apps.services.ingress;
in
  lib.mkIf cfg.enable {
    apps.services.cloudflared = {
      enable = true;
      ingress."${cfg.domain}" = "http://localhost:${toString cfg.port}";
    };
  }
