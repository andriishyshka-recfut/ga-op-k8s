
module "sftpgo-server" {
  source         = "../../../terraform-modules/k8s-vault-sftpgo-server"
  server_list    = var.Settings.clusters[var.Cluster][var.Color].sftpgo-server
  gcpProject     = var.Settings.gcpProject
  region         = var.Settings.clusters[var.Cluster].region
  sftpgo_version = var.Settings.clusters[var.Cluster][var.Color].sftpgo-server.main.version
  Cluster        = var.Cluster
  Color          = var.Color
  Settings       = var.Settings
}
