
data "vault_generic_secret" "slack" {
  path = "secret/slack/fluxcd-${var.Cluster}"
}

resource "kubernetes_secret" "slack" {
  metadata {
    name      = "slack-webhook-url"
    namespace = local.namespace
  }

  data = {
    "address" = data.vault_generic_secret.slack.data.address
  }
}
