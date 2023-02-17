# variable "GkeClusterConnectionSettings" {}
variable "Settings" {}
variable "Cluster" {}
variable "Color" {}

locals {
  elasticUsername   = data.vault_generic_secret.elastic.data["username"]
  elasticPassword   = data.vault_generic_secret.elastic.data["password"]
  grafanaUsername   = data.vault_generic_secret.grafana.data["username"]
  grafanaPassword   = data.vault_generic_secret.grafana.data["password"]
  url               = "https://g.regemini.com/"
  grafanaRole       = var.Cluster == "production" ? "Viewer" : "Editor"
  grafanaSecretpath = var.Color == "red" ? "secret/red/grafanaElastic" : "secret/grafana"
  grafanaAdmins     = ["anton.moliavko@geminiadvisory.io", "dc@geminiadvisory.io", "dmytro.kubov@geminiadvisory.io"]
  grafanaEditors    = ["anton@geminiadvisory.io"]
  grafanaViewers    = ["artem.kiazimov@geminiadvisory.io", "mk@geminiadvisory.io", "serhii.hutsaliuk@geminiadvisory.io", "vakhtang.mosidze@geminiadvisory.io", "volodymyr.kononov@geminiadvisory.io"]
}
