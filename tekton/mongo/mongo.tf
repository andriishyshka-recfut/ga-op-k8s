variable "MongoVaultPath" { }


module "mongo" {
  source              = "../../terraform-modules/k8s-vault-mongo"
  CredsPath           = var.MongoVaultPath
}
