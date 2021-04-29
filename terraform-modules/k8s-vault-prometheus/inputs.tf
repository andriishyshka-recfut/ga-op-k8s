
variable "OidcSecretVaultPath" {
  default = "secret/oidc_google_prod"
}


locals {
  prometheusNs = "monitoring"
}
