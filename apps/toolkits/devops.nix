{
  config,
  lib,
  pkgs,
  username,
  ...
}: let
  cfg = config.apps.toolkits.devops;
in {
  options.apps.toolkits.devops.enable = lib.mkEnableOption "devops / kubernetes CLI";

  config = lib.mkIf cfg.enable {
    home-manager.users.${username}.home.packages = with pkgs; [
      kubectl
      kubernetes-helm
      k9s
      kubectx
      kustomize
      stern
    ];

    # k9s / 上游 kubectl / stern 只认 ~/.kube/config; k3s 的 kubeconfig 在 /etc
    systemd.tmpfiles.rules = lib.mkIf config.apps.services.monitoring.k3s.enable [
      "d /home/${username}/.kube 0755 ${username} users -"
      "L+ /home/${username}/.kube/config - - - - /etc/rancher/k3s/k3s.yaml"
    ];
  };
}
