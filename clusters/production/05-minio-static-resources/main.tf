module "minio_prod" {
  source   = "../../../terraform-modules/minio"
  Cluster  = "production"
  Values   = local.values
}
