data "http" "grafana_dashboard_tekton" {
  url = "https://github.com/jenkins-x-charts/grafana-dashboard/blob/master/charts/grafana-dashboard/dashboards/tekton.json"

  # Optional request headers
  request_headers = {
    Accept = "application/json"
  }
}

resource "kubernetes_config_map" "tekton_dashboard" {
  metadata {
    name      = "tekton-dashboard"
    namespace = "monitoring"
    labels = {
      grafana_dashboard = 1
    }
  }

  data = {
    "tekton.json" = data.http.grafana_dashboard_tekton.body
  }

}

# data "kubectl_file_documents" "tekton_yaml" {
#   content = file("${path.module}/tekton.yaml")
# }
# resource "kubectl_manifest" "tekton" {
#   # force_new = true
#   count     = 2
#   yaml_body = element(data.kubectl_file_documents.tekton_yaml.documents, count.index)
# }

# resource "kubernetes_manifest" "tekton" {
#   count    = 2
#   manifest = yamldecode(element(data.kubectl_file_documents.tekton_yaml.documents, count.index))
# }
