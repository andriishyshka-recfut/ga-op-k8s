
resource "helm_release" "prometheus_kafka_exporter" {
  name              = "prometheus-kafka-exporter"
  repository        = "https://prometheus-community.github.io/helm-charts"
  chart             = "prometheus-kafka-exporter"
  wait              = true
  atomic            = true
  namespace         = local.prometheusNs
  dependency_update = true
  set = [
    {
      name  = "kafkaServer.0"
      value = "kafka-cluster-kafka-bootstrap.kafka:9092"
    },
    {
      name  = "prometheus.serviceMonitor.namespace"
      value = "monitoring"
    },
    {
      name  = "prometheus.serviceMonitor.enabled"
      value = "true"
    },
    {
      name  = "prometheus.serviceMonitor.additionalLabels.release"
      value = "prometheus"
    }
  ]
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
    name      = "fluxcd2-dashboards"
    namespace = "monitoring"
    labels = {
      grafana_dashboard = 1
    }
  }

  data = {
    "kafka-exporter-overview.json" = replace(data.http.grafana_dashboard.response_body, "$${DS_PROMETHEUS_WH211}", "default")
  }

}
# data "kubectl_file_documents" "rule_lag" {
#   # content = file("${path.module}/kafka-lag-prometheusrule.yaml")
#   content = templatefile("${path.module}/kafka-lag-prometheusrule.yaml", { cluster_label : var.Cluster })
# }
# resource "kubectl_manifest" "rule_lag" {
#   count     = 1
#   yaml_body = element(data.kubectl_file_documents.rule_lag.documents, count.index)
# }

# resource "kubernetes_manifest" "rule_lag" {
#   count    = 1
#   manifest = yamldecode(element(data.kubectl_file_documents.rule_lag.documents, count.index))
# }
