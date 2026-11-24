{
  config,
  pkgs,
}: name: pkg: binary:
pkgs.writeShellScriptBin name ''
  set -a
  source ${config.sops.secrets.api-key-env.path}
  set +a
  exec ${pkg}/bin/${binary} "$@"
''
