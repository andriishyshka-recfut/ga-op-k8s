
data "kubectl_file_documents" "go" {
  content = file("${path.module}/go-podmonitor.yaml")
}

resource "kubernetes_manifest" "go" {
  count     = 1
  manifest = yamldecode(element(data.kubectl_file_documents.go.documents, count.index))
}

data "http" "grafana_dashboard_go" {
  url = "https://grafana.com/api/dashboards/6671/revisions/2/download"

  # Optional request headers
  request_headers = {
    Accept = "application/json"
  }
}

resource "kubernetes_config_map" "go_dashboards" {
  metadata {
    name      = "go-dashboard"
    namespace = "monitoring"
    labels = {
      grafana_dashboard = 1
    }
  }

  data = {
    "go.json" = replace(data.http.grafana_dashboard_go.body, "$${DS_PROMETHEUS-APL}", "Prometheus")
  }

}


data "kubectl_file_documents" "go_rules" {
  # content = file("${path.module}/go-prometheusrule.yaml")
  content = templatefile("${path.module}/go-prometheusrule.yaml", { cluster_label : var.Cluster })
}

resource "kubernetes_manifest" "go_rules" {
  count     = 1
  manifest = yamldecode(element(data.kubectl_file_documents.go_rules.documents, count.index))
}

data "kubectl_file_documents" "upsert_rules" {
  content = templatefile("${path.module}/upsert-rules.yaml", { cluster_label : var.Cluster })
}

resource "kubernetes_manifest" "upsert_rules" {
  count     = 1
  manifest = yamldecode( element(data.kubectl_file_documents.upsert_rules.documents, count.index))
}
