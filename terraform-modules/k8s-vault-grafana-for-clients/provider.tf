
terraform {
  required_providers {
    kubectl = {
      source  = "registry.terraform.io/gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
    grafana = {
      source  = "registry.terraform.io/grafana/grafana"
      version = ">= 2.11.0"
    }
  }
}

# resource "grafana_organization" "elastic" {
#   provider = grafana.elastic
#   name     = "Regemini"
# #   admins   = local.grafanaAdmins
# #   editors  = local.grafanaEditors
# #   viewers  = local.grafanaViewers
# }

provider "grafana" {
  alias = "elastic"
  url   = local.url
  auth  = "${local.grafanaUsername}:${local.grafanaPassword}"
  # store_dashboard_sha256 = true
}
