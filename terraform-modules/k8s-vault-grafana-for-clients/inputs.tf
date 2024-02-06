# variable "GkeClusterConnectionSettings" {}
variable "Settings" {}
variable "Cluster" {}
variable "Color" {}

locals {
  helmVersion       = lookup(var.Settings.clusters[var.Cluster][var.Color].versions.grafana_for_clients, "helm_version", "7.3.0")
  esVersion         = lookup(var.Settings.clusters[var.Cluster][var.Color].versions.logstash, "logstash_version", "7.17.17")  
  elasticUsername   = data.vault_generic_secret.elastic.data["username"]
  elasticPassword   = data.vault_generic_secret.elastic.data["password"]
  grafanaUsername   = data.vault_generic_secret.grafana.data["username"]
  grafanaPassword   = data.vault_generic_secret.grafana.data["password"]
  url               = "https://g.regemini.com/"
  grafanaNs         = "grafana-clients"
  grafanaRole       = var.Cluster == "production" ? "Viewer" : "Editor"
  grafanaSecretpath = var.Color == "red" ? "secret/red/grafanaElastic" : "secret/grafana"
  grafanaAdmins     = ["anton.moliavko@geminiadvisory.io", "roman.kharytonov@geminiadvisory.io","dc@geminiadvisory.io", "dmytro.kubov@geminiadvisory.io", "bohdan.havrysh@geminiadvisory.io"]
  grafanaEditors    = ["anton@geminiadvisory.io"]
  grafanaViewers    = ["artem.kiazimov@geminiadvisory.io", "mk@geminiadvisory.io", "serhii.hutsaliuk@geminiadvisory.io", "volodymyr.kononov@geminiadvisory.io"]
}
