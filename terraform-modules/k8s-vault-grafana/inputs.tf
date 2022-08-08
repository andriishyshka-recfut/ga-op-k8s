variable "Settings" {}
variable "Cluster" {}
variable "Color" {}

locals {
  elasticUsername = data.vault_generic_secret.elastic.data["username"]
  elasticPassword = data.vault_generic_secret.elastic.data["password"]
  grafanaUsername = data.vault_generic_secret.grafana.data["username"]
  grafanaPassword = data.vault_generic_secret.grafana.data["password"]
  # url             = "http://localhost:3000/"
  url               = "http://grafana-clients.grafana-clients/" #  WTF????
  grafanaRole       = var.Cluster == "production" ? "Viewer" : "Editor"
  grafanaSecretpath = var.Color == "red" ? "secret/red/grafanaElastic" : "secret/grafana"
}
