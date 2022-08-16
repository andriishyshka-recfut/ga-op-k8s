terraform {
  required_providers {
    kubectl = {
      source  = "registry.terraform.io/gavinbunney/kubectl"
      version = ">= 1.10.0"
    }
    grafana = {
      source  = "registry.terraform.io/grafana/grafana"
      version = ">= 1.25.0"
    }
  }
}

provider "grafana" {
  alias = "base"
  url   = local.url
  auth  = "${local.grafanaUsername}:${local.grafanaPassword}"
}

resource "grafana_organization" "elastic" {
  provider = grafana.base
  name     = "Regemini"
  admins   = local.grafanaAdmins
  editors  = local.grafanaEditors
  viewers  = local.grafanaViewers
}

provider "grafana" {
  alias  = "elastic"
  url    = local.url
  auth   = "${local.grafanaUsername}:${local.grafanaPassword}"
  org_id = grafana_organization.elastic.org_id
}
