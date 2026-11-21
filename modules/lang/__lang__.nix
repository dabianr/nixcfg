{
  lib,
  ...
}: {
  imports = [
    ./c-cpp.nix
    ./javascript.nix
    ./python.nix
    ./rust.nix
    ./go.nix
    ./java.nix
  ];

  options.modules = {
    lang.list = lib.mkOption {
      type = lib.types.nullOr (lib.types.listOf (lib.types.enum [
        "c-cpp"
        "go"
        "java"
        "javascript"
        "python"
        "rust"
      ]));
      default = [];
      description = "programming languages toolchains";
    };
  };
}
