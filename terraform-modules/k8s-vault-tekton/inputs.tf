variable "Cluster" {}
variable "Color" {}
variable "GkeClusterConnectionSettings" {}
variable "VaultAddress" {}
variable "Settings" {}

locals {
  tekton_ns_list     = ["tekton-pipelines", "tekton-tasks"]
  tektonMainNs       = "tekton-pipelines"
  tektonNs           = "tekton-tasks"
  mongoCredsPath     = "secret/mongo/tekton"
  gkeClusterEndpoint = var.GkeClusterConnectionSettings.HOST
  gkeBearerToken     = var.GkeClusterConnectionSettings.API_KEY
  configPath         = var.Cluster == "production" ? "prod.tfvars.json" : "config.tfvars.json"
  registry_server    = "harbor.regemini.io"
  resources = {
    "tekton-operator" = {
      "default" = {
        "cpu"    = "150m",
        "memory" = "256Mi"
      }
      "defaultRequest" = {
        "cpu"    = "50m",
        "memory" = "64Mi"
      }
      "max" = {
        "cpu"    = "1",
        "memory" = "2Gi"
      }
      "min" = {
        "cpu"    = "20m",
        "memory" = "28Mi"
      }
    }
    "tekton-pipelines" = {
      "default" = {
        "cpu"    = "350m",
        "memory" = "512Mi"
      }
      "defaultRequest" = {
        "cpu"    = "50m",
        "memory" = "128Mi"
      }
      "max" = {
        "cpu"    = "1000m",
        "memory" = "4Gi"
      }
      "min" = {
        "cpu"    = "20m",
        "memory" = "24Mi"
      }
    }
    "tekton-tasks" = {
      "default" = {
        "cpu"    = "500m",
        "memory" = "512Mi"
      }
      "defaultRequest" = {
        "cpu"    = "50m",
        "memory" = "128Mi"
      }
      "max" = {
        "cpu"    = "1000m",
        "memory" = "1500Mi"
      }
      "min" = {
        "cpu"    = "20m",
        "memory" = "24Mi"
      }
    }
  }
}
