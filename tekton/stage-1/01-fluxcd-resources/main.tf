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
        # url = "https://github.com/recfut/ga-op-k8s-configs.git",
        # provider = "github",
        url        = "https://gitlab.regemini.com/op/k8s-configs.git",
        git_branch = var.Cluster
      },
      op-charts = {
        # url = "https://github.com/recfut/ga-op-charts.git",
        # provider = "github",
        url        = "https://gitlab.regemini.com/op/charts.git",
        git_branch = "main"
      },
      gitops = {
        # url = "https://github.com/recfut/ga-op-gitops.git",
        # provider = "github",
        url        = "https://gitlab.regemini.com/op/gitops.git",
        git_branch = var.Cluster
      }
    },
    helm-repositories = {
      op = {
        type            = "oci",
        url             = "oci://harbor.regemini.io/helm"
        secret_ref      = "helm-credentials"
        # url             = "oci://${local.artifactoryRepoDomain}/ga-helm-local",
        # secret_ref      = "artifactory-client-creds",
        # cert_secret_ref = "artifactory-client-mtls"
      },
      ww-gitops = {
        type = "oci",
        url  = "oci://ghcr.io/weaveworks/charts"
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
    },
    kustomizations = merge(
      {
        prometheus-main-rules = {
          kustomization_path = "./monitoring/prometheus/main-rules",
          git_repository     = "gitops"
        }
      },
      {
        cluster-wide = {
          kustomization_path = "./kyverno-policies/cluster-wide"
          git_repository     = "gitops"
        }
      },
      {
        cert-manager = {
          kustomization_path = "./kyverno-policies/cert-manager"
          git_repository     = "gitops"
        }
      },
      var.Cluster == "sandbox" ? {
        cvat = {
          kustomization_path = "./kyverno-policies/cvat"
          git_repository     = "gitops"
        }
      } : {}
    )
  }
}
