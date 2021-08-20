
module "mongo" {
  source              = "../../../terraform-modules/k8s-vault-mongo"
  CredsPath           = "secret/mongo/magescanner"
}
