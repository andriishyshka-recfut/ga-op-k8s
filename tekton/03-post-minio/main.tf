module "post_minio" {
  source   = "../../terraform-modules/k8s-post-minio"
  Cluster  = var.Cluster
  Settings = var.Settings
  Color    = var.Color
}

