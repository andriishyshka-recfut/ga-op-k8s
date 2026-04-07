variable "Settings" {}
variable "Cluster" {}
variable "Color" {}

variable "OidcSecretVaultPath" {
  default = "secret/oidc_google_prod"
}

data "vault_generic_secret" "okta_oidc" {
  path = "secret/misc/oidc/okta/grafana"
}

locals {
  helmVersion             = lookup(var.Settings.clusters[var.Cluster].versions.prometheus, "helm_version", "17.0.0")
  thanosSidecarVersion    = lookup(var.Settings.clusters[var.Cluster].versions.thanos, "app_version", "0.28.1")
  thanosBucket            = lookup(var.Settings.clusters[var.Cluster][var.Color].prometheus.thanos, "storage_bucket", "minio-prometheus-thanos-ardent-rarity-239115")
  prometheusNs            = "monitoring"
  grafanaRole             = var.Cluster == "production" ? "Viewer" : "Editor"
  prometheusExtUrl        = lookup(var.Settings.clusters[var.Cluster][var.Color].prometheus, "prometheusExtUrl", "http://localhost:9090")
  prometheusConfigFile    = var.Color == "red" ? "red-kube-prometheus-stack-values.tftpl" : "kube-prometheus-stack-values.tftpl"
  grafanaSecretpath       = var.Color == "red" ? "secret/red/grafana" : "secret/grafana"
  slackSecretPath         = "secret/misc/slack/app/AlertManager"
  thanosMinioUser         = "thanos"
  prometheusQueryUrl      = var.Cluster == "production" ? "https://prometheus.p.regemini.io/query/" : "https://prometheus.t.regemini.io/query/"
  prometheusResources     = {
    RAMreq                = var.Cluster == "production" ? "5.5Gi" : "3.5Gi"
    RAMlim                = var.Cluster == "production" ? "6.0Gi" : "4.0Gi"
    CPUreq                = var.Cluster == "production" ? "1500m" : "1100m"
    CPUlim                = var.Cluster == "production" ? "1600m" : "1300m"
  }  
  prometheusSlackWebHooks = data.vault_generic_secret.prometheus.data
  grafana_okta = {
    enabled             = true
    client_id           = data.vault_generic_secret.okta_oidc.data.client_id
    issuer              = data.vault_generic_secret.okta_oidc.data.issuer
    org_mapping         = "\"*:1:Viewer\""
    role_attribute_path = "contains(groups[*], 'APP-GA-OP') && 'GrafanaAdmin'",
    allowed_groups      = "APP-GA-OP,APP-GA-DEV,APP-GA-PM,APP-GA-GRAFANA,APP-GA-HUNT"
  }
}

terraform {
  required_providers {
    kubectl = {
      source  = "registry.terraform.io/gavinbunney/kubectl"
      version = ">= 1.10.0"
    }
  }
}
