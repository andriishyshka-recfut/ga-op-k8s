module "kubescape" {
  source   = "../../terraform-modules/k8s-vault-sonarqube"
  Settings = var.Settings
  Cluster  = var.Cluster
  Color    = var.Color
}