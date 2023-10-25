
terraform {
  required_providers {
    kubectl = {
      source  = "registry.terraform.io/gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
    grafana = {
      source  = "registry.terraform.io/grafana/grafana"
      version = ">= 2.0.0"
    }
  }
}

provider "grafana" {  
  alias                  = "base"
  url                    = local.url
  auth                   = "${local.grafanaUsername}:${local.grafanaPassword}"
  # store_dashboard_sha256 = true
}

resource "grafana_organization" "elastic" {
  provider = grafana.base
  name     = "Regemini"
  # org_id = 2
  # admins   = local.grafanaAdmins
  # editors  = local.grafanaEditors
  # viewers  = local.grafanaViewers
}

provider "grafana" { 
  alias                  = "elastic"
  url                    = local.url
  auth                   = "${local.grafanaUsername}:${local.grafanaPassword}"
  org_id                 = grafana_organization.elastic.org_id
  # store_dashboard_sha256 = true
}
