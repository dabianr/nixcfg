{
  config,
  lib,
  ...
}: {
  imports = [
    ./ai/__ai__.nix
    ./proxy/__proxy__.nix
    ./remote/__remote__.nix
    ./monitoring/__monitoring__.nix
  ];
}
