
module "mongo" {
  source     = "../../../terraform-modules/k8s-vault-mongo"
  CredsPath  = "secret/mongo/magescanner"
  depends_on = [module.namespaces]
}
