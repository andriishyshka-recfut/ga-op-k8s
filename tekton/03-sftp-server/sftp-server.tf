
module "sftp-server" {
  source         = "../../terraform-modules/k8s-vault-sftp-server"
  server_list    = var.Settings.clusters[var.Cluster].sftp-server
}