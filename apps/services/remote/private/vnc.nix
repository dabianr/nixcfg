{
  pkgs,
  username,
  lib,
  config,
  ...
}: let
  cfg = config.apps.services.remote.private.vnc;
in {
  options.apps.services.remote.private.vnc.enable =
    lib.mkEnableOption "wayvnc + novnc";
  options.apps.services.remote.private.vnc.reverseProxy =
    lib.mkEnableOption "novnc 反代";
  options.apps.services.remote.private.vnc.auto =
    lib.mkEnableOption "自启动";

  config = lib.mkIf cfg.enable (lib.mkMerge [
    # ---- 基础：装包 + wayvnc 配置 + 启动服务 ----
    {
      environment.systemPackages = with pkgs; [
        wayvnc
        novnc
        wlr-randr
      ];

      home-manager.users.${username}.xdg.configFile."wayvnc/config" = {
        text = ''
          address=127.0.0.1
          port=5900
          xkb_layout=us
          xkb_variant=
          xkb_options=
        '';
      };
    }

    (lib.mkIf cfg.auto {
        systemd.user.services.wayvnc = {
        description = "WayVNC (127.0.0.1:5900)";
        wantedBy = [ "default.target" ];
        serviceConfig = {
          ExecStart = "${pkgs.wayvnc}/bin/wayvnc -r 127.0.0.1 5900";
          Restart = "on-failure";
          Environment = [ "WAYLAND_DISPLAY=wayland-1" ];  # 按实际调整
        };
      };

      systemd.services.novnc = {
        description = "noVNC proxy 127.0.0.1:6080 -> 127.0.0.1:5900";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];
        # novnc 启动脚本用 ps 做存活检查, 默认 service PATH 里没有 procps
        path = [ pkgs.procps ];
        serviceConfig = {
          ExecStart = "${lib.getExe pkgs.novnc} --vnc 127.0.0.1:5900 --listen 127.0.0.1:6080";
          Restart = "on-failure";
        };
      };
    })

    # ---- nginx 反代 ----
    (lib.mkIf cfg.reverseProxy {
      # nix-shell -p apacheHttpd --run 'htpasswd -B -n dabianchaoren'
      sops.secrets.nginx-basic-auth-hash = {
        sopsFile = config.secrets.path + "/token.yaml";
        mode = "0400";
        owner = "nginx";
        group = "nginx";
      };

      sops.templates."nginx-htpasswd" = {
        owner = "nginx";
        group = "nginx";
        mode = "0400";
        content = lib.replaceStrings
          [ "BASIC_AUTH_HASH_PLACEHOLDER" ]
          [ config.sops.placeholder."nginx-basic-auth-hash" ]
          "dabianchaoren:BASIC_AUTH_HASH_PLACEHOLDER";
      };

      services.nginx = {
        enable = true;
        recommendedProxySettings = true;

        virtualHosts."1.ccb" = {
          default = true;
          onlySSL = true;
          basicAuthFile = config.sops.templates."nginx-htpasswd".path;
          sslCertificate = "/etc/nginx/ssl/cert.pem";
          sslCertificateKey = "/etc/nginx/ssl/key.pem";
          listen = [
            { addr = "[::]"; port = 49514; ssl = true; }
          ];

          locations."/" = {
            proxyPass = "http://127.0.0.1:6080";
            proxyWebsockets = true;
            extraConfig = ''
              proxy_pass_header Authorization;
            '';
          };
        };
      };

      networking.firewall.allowedTCPPorts = [ 49514 ];

      system.activationScripts.nginx-ssl-cert = ''
        if [ ! -f /etc/nginx/ssl/cert.pem ]; then
          mkdir -p /etc/nginx/ssl
          chown root:nginx /etc/nginx/ssl
          chmod 755 /etc/nginx/ssl
          ${pkgs.openssl}/bin/openssl req -x509 -newkey rsa:4096 \
            -keyout /etc/nginx/ssl/key.pem \
            -out /etc/nginx/ssl/cert.pem \
            -days 365 -nodes \
            -subj "/CN=1.ccb"
          chown root:nginx /etc/nginx/ssl/key.pem /etc/nginx/ssl/cert.pem
          chmod 644 /etc/nginx/ssl/cert.pem
          chmod 640 /etc/nginx/ssl/key.pem
        fi
      '';
    })
  ]);
}