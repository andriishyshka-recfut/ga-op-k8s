
module "sftpgo-clients" {
  source         = "../../terraform-modules/k8s-vault-sftpgo-clients"
  sftp_url       = var.Settings.clusters[var.Cluster].sftp-clients.main.sftp_url
}