module "fluxcd_resources" {
  source  = "../../../terraform-modules/k8s-vault-fluxcd-resources"
  Cluster = var.Cluster
  Color   = var.Color
  Values  = local.values
}

locals {
  values = {
    git-repositories = {
      k8s-configs = {
        url        = "https://gitlab.regemini.com/op/k8s-configs.git",
        git_branch = var.Cluster
      },
      op-charts = {
        url        = "https://gitlab.regemini.com/op/charts.git",
        git_branch = "main"
      },
      gitops = {
        url        = "https://gitlab.regemini.com/op/gitops.git",
        git_branch = var.Cluster
      }
    },
    helm-repositories = {
      op = {
        type = "oci",
        url  = "oci://harbor.regemini.io/helm"
      },
      ww-gitops = {
        type = "oci",
        url  = "oci://ghcr.io/weaveworks/charts"
      }
    },
    kustomizations = {
      k8s-configs = {
        kustomization_path = "./clusters/${var.Cluster}-${var.Color}",
        git_repository     = "k8s-configs"
      }
      cluster-wide-red = {
        kustomization_path = "./kyverno-policies/cluster-wide-red"
        git_repository     = "gitops"
      }
    },
    notification-providers = {
      slack = {
        type         = "slack",
        slack_chanel = "fluxcd-${var.Cluster}"
        webhook_url  = "slack-webhook-url"
      }
    },
    alerts = {
      global = {
        provider      = "slack"
        event_sources = ["GitRepository", "Kustomization"]
      },
      helm-alerts = {
        provider       = "slack"
        event_sources  = ["HelmRelease", "HelmRepository"]
        exclusion_list = ["Fetched revision", "failed to download repository index"]
      }
    }
  }
}
