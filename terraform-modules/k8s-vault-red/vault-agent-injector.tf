resource "helm_release" "vault_agent_injector" {
  name = "vault-agent-injector"
  chart      = "vault"
  repository = "https://helm.releases.hashicorp.com"
  namespace         = "vault"
  dependency_update = "true"
  values = [
    file("${path.module}/values-agent-injector.yaml")
  ]
  set {
    name  = "injector.externalVaultAddr"
    value = "https://${local.vaultFqdn}"
  }
}
