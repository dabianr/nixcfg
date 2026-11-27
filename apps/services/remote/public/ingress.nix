{
  config,
  lib,
  ...
}: let
  cfg = config.apps.services.remote.public.ingress;
  domain = "app.bigdogbarks.top";
  port = 8082;
in {
  options.apps.services.remote.public.ingress = {
    enable = lib.mkEnableOption "ingress services (cloudflared tunnel + nginx)";
    domain = lib.mkOption {
      type = lib.types.str;
      default = domain;
      description = "ingress 域名";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = port;
      description = "nginx 监听端口";
    };
  };

  config = lib.mkIf cfg.enable {
    services.nginx = {
      enable = true;
      recommendedProxySettings = true;

      # 裸 TCP 转发（nginx 默认 --with-stream）：外网口 -> 本机工具口
      # 反弹 shell: nc -lvnp 14444
      # RMI:        rmiregistry 11099 / JNDIExploit -i <本机外网 IP>
      streamConfig = ''
        server {
          listen 4444;
          proxy_pass 127.0.0.1:14444;
          proxy_timeout 1h;
        }
        server {
          listen 1099;
          proxy_pass 127.0.0.1:11099;
          proxy_timeout 1h;
        }
      '';

      virtualHosts."${cfg.domain}" = {
        listen = [
          {
            addr = "127.0.0.1";
            port = cfg.port;
          }
        ];

        # 后端 API / 上传的图片
        locations =
          lib.genAttrs ["/api/" "/uploads/"] (path: {
            proxyPass = "http://127.0.0.1:8000${path}";
            proxyWebsockets = true;
          })
          // {
            # 无公网 IP：反向 shell 走 HTTP 信标（beacon.py 监听 127.0.0.1:8899，长轮询，别缓冲）
            "= /sh" = {
              proxyPass = "http://127.0.0.1:8899";
              extraConfig = ''
                proxy_read_timeout 60s;
                proxy_buffering off;
              '';
            };

            # 前端 (Vite dev / 静态文件)
            "/" = {
              proxyPass = "http://127.0.0.1:5173/";
              proxyWebsockets = true;
            };
          };
      };
    };

    networking.firewall.allowedTCPPorts = [4444 1099];

    apps.services.remote.cloudflared = {
      enable = true;
      ingress."${cfg.domain}" = "http://localhost:${toString cfg.port}";
    };
  };
}
