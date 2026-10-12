module "minio_prod" {
  source  = "../../../terraform-modules/minio"
  Cluster = "production"
  Color   = var.Color
  Values  = local.values
}
