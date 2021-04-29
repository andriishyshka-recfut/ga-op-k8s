
resource "helm_release" "prometheus_kafka_exporter" {
  name              = "prometheus-kafka-exporter"
  repository        = "https://prometheus-community.github.io/helm-charts"
  chart             = "prometheus-kafka-exporter"
  wait              = true
  atomic            = true
  namespace         = local.prometheusNs
  dependency_update = true
  set {
    name  = "kafkaServer.0"
    value = "kafka-cluster-kafka-bootstrap.kafka:9092"
  }
  set {
    name = "prometheus.serviceMonitor.namespace"
    value = "monitoring"
  }
  set {
    name = "prometheus.serviceMonitor.enabled"
    value = "true"
  }
  set {
    name = "prometheus.serviceMonitor.additionalLabels.release"
    value = "prometheus"
  }
}

#
# https://grafana.com/api/dashboards/7589/revisions/5/download

data "http" "grafana_dashboard" {
  url = "https://grafana.com/api/dashboards/7589/revisions/5/download"

  # Optional request headers
  request_headers = {
    Accept = "application/json"
  }
}

resource "kubernetes_config_map" "kafka_exporter_dashboard" {
  metadata {
    name = "fluxcd2-dashboards"
    namespace = "monitoring"
    labels = {
      grafana_dashboard = 1
    }
  }

  data = {
    "kafka-exporter-overview.json"             = replace(data.http.grafana_dashboard.body, "$${DS_PROMETHEUS_WH211}","Prometheus")
  }

}
