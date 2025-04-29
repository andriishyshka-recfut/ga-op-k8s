
module "fluxcd" {
  source  = "../../../terraform-modules/k8s-vault-fluxcd-resources"
  Cluster = var.Cluster
  Color   = var.Color
  Values  = local.values
  k8s     = local.gkeClusterConnectionSettings
}

locals {
  values = {
    helm-releases = {
      ww-gitops = {
        chart_name      = "weave-gitops",
        helm_repository = "ww-gitops",
        additional_args = ["--insecure-no-authentication-user=gitops-test-user"]
      }
    },
    kustomizations = {
      all = {
        kustomization_path = "./clusters/${var.Cluster}-${var.Color}",
        git_repository     = "k8s-configs"
      }
    }
  }
}
