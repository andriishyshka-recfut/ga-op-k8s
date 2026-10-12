variable "GkeClusterConnectionSettings" {}
variable "Settings" {}
variable "Cluster" {}
variable "Color" {}

data "vault_generic_secret" "okta" {
  path = "secret/misc/oidc/okta/minio"
}

resource "kubernetes_secret" "okta-oidc" {
  metadata {
    name      = "okta-oidc"
    namespace = local.minioNs
  }
  data = {
    "client_id"     = data.vault_generic_secret.okta.data["client_id"]
    "client_secret" = data.vault_generic_secret.okta.data["client_secret"]
  }
}

locals {
  minioNs = "minio-helm"
  ansibleEnvs = merge(var.GkeClusterConnectionSettings, {
    ANSIBLE_STDOUT_CALLBACK = "debug"
  })

  vaultUsersCredentialsPath = "${var.Settings.clusters[var.Cluster][var.Color].minio.vault_users_config_path}/users"
  vaultRootCredentialsPath  = var.Settings.clusters[var.Cluster][var.Color].minio.vault_root_config_path
  vaultOidcConfigPath       = var.Settings.clusters[var.Cluster][var.Color].minio.vault_oidc_config_path
  minioFqdn                 = var.Cluster == "production" ? "minio-helm.p.regemini.io" : "minio-helm.t.regemini.io"
  vaultFqdn                 = var.Cluster == "production" ? "https://vault.p.regemini.io" : "https://vault.t.regemini.io"
  minioConsoleFqdn          = var.Settings.clusters[var.Cluster][var.Color].minio.console_fqdn
  currentProject            = var.Settings.gcpProject
  imageTag                  = var.Settings.clusters[var.Cluster].versions.minio.image_tag
  mcImageTag                = "RELEASE.2023-09-13T23-08-58Z"
  pv_disk_count             = var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.services.minio.data.count
  diskSize                  = var.Settings.clusters[var.Cluster].persistent_resources.permanentDisks.services.minio.data.size
  runUserAccess             = 0
  cert_dns_names            = ["minio.minio-helm.svc.cluster.local", "*.minio-helm.svc.cluster.local", "*.minio.minio-helm.svc.cluster.local", "*.minio-tenant-console.minio-helm.svc.cluster.local", "*.minio-tenant-hl.minio-helm.svc.cluster.local"]
  minioSettings = {
    redirect_url = local.minioFqdn
    oidc = {
      issuer        = data.vault_generic_secret.okta.data["issuer"]
      secretName    = "okta-oidc"
      claimName     = "groups"
      scopes        = "openid,profile,email,groups"
      client_id     = data.vault_generic_secret.okta.data["client_id"]
      client_secret = data.vault_generic_secret.okta.data["client_secret"]
    }
    root        = data.vault_generic_secret.root_credentials_from_vault.data
    repository  = "harbor.regemini.io/mirror/minio"
    pull_secret = "harbor"
  }
}
