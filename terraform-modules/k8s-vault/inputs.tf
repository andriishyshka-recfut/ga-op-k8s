

variable "GkeClusterConnectionSettings" {}

// Cluster variables and settings from common-vars module
variable "Settings" {}
variable "Cluster" {}
variable "Color" {}
// OIDC setup settings. Should be passed as env variables during execution
variable "OidcDiscoveryUrl" { default = "SAMPLE" }
variable "OidcClientId" { default = "SAMPLE" }
variable "OidcClientSecret" { default = "SAMPLE" }
variable "VaultAddress" {}


data "google_client_config" "current" {}

locals {
  vaultBucketName       = var.Settings.clusters[var.Cluster].persistent_resources.vault_bucket_name
  vaultKeyName          = var.Settings.clusters[var.Cluster].persistent_resources.vault_key_name
  vaultServiceAccountId = var.Settings.clusters[var.Cluster].persistent_resources.vault_service_account_id

  vaultFqdn     = var.Settings.clusters[var.Cluster][var.Color].vault.fqdn
  vaultLocalUrl = "http://vault.vault.svc"

  cluster = var.Cluster


  gkeClusterEndpoint = var.GkeClusterConnectionSettings.HOST
  ansibleEnvs = merge(var.GkeClusterConnectionSettings, {
    CLUSTER_SETTINGS        = jsonencode(var.Settings)
    CLUSTER                 = var.Cluster
    COLOR                   = var.Color
    ANSIBLE_STDOUT_CALLBACK = "debug"
    BASTION_DNS             = var.Settings.bastion_dns
    vault_addr              = "https://${local.vaultFqdn}"
  })

  // toggles
  initialProvisioningToggle = var.Settings.clusters[var.Cluster][var.Color].vault.do_initial_provisioning ? 1 : 0
  certManagerIssuerToggle   = var.Settings.clusters[var.Cluster][var.Color].vault.create_cert-manager_issuer ? 1 : 0
  # istioExposeToggle         = var.Settings.clusters[var.Cluster][var.Color].vault.istio_expose ? 1 : 0
  replicasCount  = 0
  vaultVersion   = var.Settings.clusters[var.Cluster].versions.vault.version
  vaultImage     = lookup(var.Settings.clusters[var.Cluster].versions.vault, "image", false)
  currentProject = data.google_client_config.current.project
  vaultIssuer = {
    name         = "vault-issuer"
    mountPath    = "/v1/auth/k8s-${var.Cluster}-${var.Color}"
    vaultRole    = "cert-manager"
    secretName   = "sa-${var.Cluster}-cert-manager"
    vaultAddress = var.VaultAddress
    pkiRole      = "elastic"
    pkiPath      = "pki-elastic-int"
  }
}
