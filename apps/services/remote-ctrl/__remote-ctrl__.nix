{
  config,
  lib,
  ...
}: {
  imports = [
    ./nginx.nix
    ./vnc.nix
    ./easytier.nix
  ];
}
