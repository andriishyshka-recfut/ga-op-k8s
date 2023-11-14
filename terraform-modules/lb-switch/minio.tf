module "minio_domains" {
  source     = "../../../terraform-modules/k8s-post-minio"
  Cluster    = var.Cluster
  Settings   = var.Settings
  Color      = var.Color
  depends_on = [null_resource.ansible_bastion_playbook]
}
