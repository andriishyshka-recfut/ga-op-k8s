
data "vault_generic_secret" "slack" {
  path = "secret/slack/fluxcd-${var.Cluster}"
}

resource "kubernetes_secret" "slack" {
  metadata {
    name      = "slack-webhook-url"
    namespace = data.flux_install.main.namespace
  }

  data = {
    "address" = data.vault_generic_secret.slack.data.address
  }
  depends_on = [kubectl_manifest.install]
}

locals {
  alert = file("${path.module}/alert.yaml")
  provider = replace(
                  file("${path.module}/slack-notification-provider.yaml"),
                  "CHANGEME",
                   "fluxcd-${var.Cluster}"
            )
}
resource "kubectl_manifest" "provider" {
  yaml_body  = local.provider
}
resource "kubectl_manifest" "alert" {
  yaml_body  = local.alert
}
