# variable "GkeClusterConnectionSettings" {}
variable "Settings" {}
variable "Cluster" {}
variable "Color" {}

data "vault_generic_secret" "okta_oidc" {
  path = "secret/misc/oidc/okta/grafana"
}

locals {
  helmVersion       = "7.3.0"
  esVersion         = "7.17.17"
  elasticUsername   = data.vault_generic_secret.elastic.data["username"]
  elasticPassword   = data.vault_generic_secret.elastic.data["password"]
  grafanaUsername   = data.vault_generic_secret.grafana.data["username"]
  grafanaPassword   = data.vault_generic_secret.grafana.data["password"]
  url               = "https://g.regemini.com/"
  org_id            = "1"
  grafanaNs         = "grafana-clients"
  grafanaRole       = var.Cluster == "production" ? "Viewer" : "Editor"
  grafanaSecretpath = var.Color == "red" ? "secret/red/grafanaElastic" : "secret/grafana"
  grafanaSettings = {
    adminPassword = data.vault_generic_secret.grafana.data.password
    rootUrl       = data.vault_generic_secret.grafana.data.root_url
    okta = {
      enabled             = true
      client_id           = data.vault_generic_secret.okta_oidc.data.client_id
      issuer              = data.vault_generic_secret.okta_oidc.data.issuer
      org_mapping         = "\"*:1:Viewer\""
      role_attribute_path = "contains(groups[*], 'APP-GA-OP') && 'GrafanaAdmin'",
      allowed_groups      = "APP-GA-OP,APP-GA-DEV,APP-GA-COLLECT"
    }
  }
}
