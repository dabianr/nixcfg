{
  config,
  lib,
  ...
}: let
  cfg = config.apps.services.monitoring.prometheus;
in {
  options.apps.services.monitoring.prometheus = {
    enable = lib.mkEnableOption "kube-prometheus-stack inside k3s";

    namespace = lib.mkOption {
      type = lib.types.str;
      default = "monitoring";
      description = "Kubernetes namespace for the Prometheus stack.";
    };
  };

  config = lib.mkIf (cfg.enable && config.apps.services.monitoring.k3s.enable) {
    # chart 在 build 时拉取并锁 hash, 由 k3s helm-controller 部署, 不再开机跑 helm。
    # 首次从旧的 systemd+helm 方案迁移: 先 `helm -n monitoring uninstall kube-prometheus-stack` 再 rebuild。
    services.k3s.autoDeployCharts.kube-prometheus-stack = {
      name = "kube-prometheus-stack";
      repo = "https://prometheus-community.github.io/helm-charts";
      version = "93.6.1";
      hash = "sha256-biqBiCtIg4WEcJUrCgI2aqyQbcJTvxBXNg+CUmWX/eQ=";
      targetNamespace = cfg.namespace;
      createNamespace = true;
      values = {
        prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues = false;
        grafana.service = {
          type = "NodePort";
          nodePort = 30300;
        };
        prometheus.service = {
          type = "NodePort";
          nodePort = 30900;
        };
        alertmanager.service = {
          type = "NodePort";
          nodePort = 30903;
        };
      };
    };
  };
}
