{
  imports = [
    ./public/ingress.nix
    ./private/vnc.nix
    ./private/easytier.nix
    ./private/streaming.nix
    ./cloudflared.nix
  ];
}
