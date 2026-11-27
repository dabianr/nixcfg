{
  config,
  lib,
}: let
  names = ["airport01URL" "airport02URL" "airport03URL" "airport04URL"];
  toPlaceholder = name:
    lib.replaceStrings ["URL"] ["_URL"] (lib.toUpper name) + "_PLACEHOLDER";
in {
  secrets = lib.genAttrs names (_: {
    sopsFile = config.secrets.path + "/token.yaml";
  });

  substitute = template:
    lib.replaceStrings
    (map toPlaceholder names)
    (map (name: config.sops.placeholder.${name}) names)
    template;
}
