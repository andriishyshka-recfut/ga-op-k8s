module "minio_sbx" {
  source  = "../../../terraform-modules/minio"
  Cluster = "sandbox"
  Values  = local.values
  Color   = var.Color
}
