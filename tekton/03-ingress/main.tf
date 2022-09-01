module "ingress" {
  source   = "../../terraform-modules/k8s-ingress"
  Cluster  = var.Cluster
  Settings = var.Settings
}

output "ingressSettings" {
  value = module.ingress.ingressSettings
}

output "certManager" {
  value = module.ingress.certManager
}
