variable "GkeClusterConnectionSettings" {}
variable "Settings" {}
variable "Cluster" {}
variable "Color" {}
variable "VaultAddress" {}
# variable "OidcDiscoveryUrl" {}
# variable "OidcClientId" {}
# variable "OidcClientSecret" {}

locals {
  vault_auth_secret_name = "vault-k8s-auth-secret"
  vaultFqdn     = "vault.p.regemini.io"
  vaultLocalUrl = "http://vault.vault.svc"
}