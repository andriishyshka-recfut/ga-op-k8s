
data "vault_generic_secret" "slack" {
  path = "secret/misc/slack/app/FluxCD"
}

resource "kubernetes_secret" "slack" {
  metadata {
    name      = "slack-webhook-url"
    namespace = local.namespace
  }

  data = {
    "address" = data.vault_generic_secret.slack.data[local.vault_slack_key]
  }
}
