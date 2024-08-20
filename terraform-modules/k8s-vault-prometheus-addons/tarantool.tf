data "http" "grafana_dashboard_tarantool" {
  url = "https://grafana.com/api/dashboards/13054/revisions/18/download"

  # Optional request headers
  request_headers = {
    Accept = "application/json"
  }
}

resource "kubernetes_config_map" "tarantool_dashboard" {
  metadata {
    name      = "tarantool-dashboard"
    namespace = "monitoring"
    labels = {
      grafana_dashboard = 1
    }
  }

  data = {
    "tarantool.json" = data.http.grafana_dashboard_tarantool.body
  }

}

data "kubectl_file_documents" "tarantool_yaml" {
  content = file("${path.module}/tarantool.yaml")
}
# resource "kubectl_manifest" "tarantool" {
#   # force_new = true
#   count     = 2
#   yaml_body = element(data.kubectl_file_documents.tarantool_yaml.documents, count.index)
# }

resource "kubernetes_manifest" "tarantool" {
  count    = 2
  manifest = yamldecode(element(data.kubectl_file_documents.tarantool_yaml.documents, count.index))
}
