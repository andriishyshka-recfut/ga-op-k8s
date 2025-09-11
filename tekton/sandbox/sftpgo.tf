
# module "sftpgo-server" {
#   source         = "../../terraform-modules/k8s-vault-sftpgo-server"
#   server_list    = var.Settings.clusters[var.Cluster][var.Color].sftpgo-server
#   gcpProject     = var.Settings.gcpProject
#   region         = var.Settings.clusters[var.Cluster].region
#   Settings       = var.Settings
#   Cluster        = var.Cluster
#   Color          = var.Color
# }
