
module "sftpgo-server" {
  source         = "../../terraform-modules/k8s-vault-sftpgo-server"
  server_list    = try(var.Settings.clusters[var.Cluster].sftpgo-server, var.Settings.clusters[var.Cluster][var.Color].sftpgo-server)
  gcpProject     = var.Settings.gcpProject
  region         = var.Settings.clusters[var.Cluster].region
  sftpgo_values  = local.sftpgo_values
  sftpgo_version = var.Settings.clusters[var.Cluster][var.Color].sftpgo-server.version
}
