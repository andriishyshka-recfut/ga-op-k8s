
resource "helm_release" "vault_agent_injector" {
  name = "vault-agent-injector"
  #chart = "${path.module}/umbrella-vault"
  chart      = "vault"
  repository = "https://helm.releases.hashicorp.com"
  #version           = "0.1.0"
  namespace         = "vault"
  dependency_update = "true"
  values = [
    file("${path.module}/values-agent-injector.yaml")
  ]
  set = [{
    name  = "injector.externalVaultAddr"
    value = "https://${local.vaultFqdn}"
  }]
  depends_on = [
    kubernetes_secret.kms_creds,
    kubernetes_namespace.vault,
    helm_release.vault
  ]
}

resource "helm_release" "vault" {
  name = "vault"
  #chart = "${path.module}/umbrella-vault"
  chart             = "vault"
  repository        = "https://helm.releases.hashicorp.com"
  version           = local.vaultVersion
  namespace         = "vault"
  dependency_update = "true"
  values = [
    templatefile("${path.module}/templates/values-vault.tftpl", {values={google_project = local.currentProject,replicas = local.replicasCount, image = local.vaultImage}})
  ]
  set = [
  {
    name  = "server.extraEnvironmentVars.GOOGLE_PROJECT"
    value = local.currentProject
  },
  {
    name  = "server.ha.replicas"
    value = local.replicasCount
  },
  {
    name = "server.ha.config"
    value = templatefile("${path.module}/vault_config.tmpl", {
      key_ring   = local.vaultKeyName,
      crypto_key = local.vaultKeyName,
      bucket     = local.vaultBucketName
      project    = local.currentProject
    })
  }
  ]
  depends_on = [
    kubernetes_secret.kms_creds,
    kubernetes_namespace.vault,

  ]
}

data "google_service_account" "vault_sa" {
  account_id = local.vaultServiceAccountId
}

resource "google_service_account_key" "vault_key" {
  service_account_id = data.google_service_account.vault_sa.name
  # valid_before = timeadd(timestamp(), "2M")
}

resource "kubernetes_secret" "kms_creds" {
  metadata {
    name      = "kms-creds"
    namespace = "vault"
  }
  data = {
    "credentials.json" = base64decode(google_service_account_key.vault_key.private_key)
  }
  depends_on = [
    google_service_account_key.vault_key,

  ]
}

resource "kubernetes_namespace" "vault" {
  metadata {
    name = "vault"
    labels = {
      istio-injection = "enabled"
    }
  }
}
