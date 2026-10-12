data "vault_generic_secret" "slackNotification" {
  count = lookup(local.globalSettings.addons.notifications, "slack", 0) != 0 ? 1 : 0
  path  = lookup(local.globalSettings.addons.notifications, "slack", 0) != 0 ? local.globalSettings.addons.notifications.slack.vault_path : ""
}

resource "kubernetes_secret" "slackNotification" {
  count = lookup(local.globalSettings.addons.notifications, "slack", 0) != 0 ? 1 : 0
  metadata {
    name      = "slack-notification"
    namespace = local.globalSettings.namespace
  }
  wait_for_service_account_token = true
  data = {
    "xpack.notification.slack.account.monitoring.secure_url" = data.vault_generic_secret.slackNotification.0.data.slack_account_monitoring_secure_url
  }
}

data "vault_generic_secret" "smtpNotification" {
  count = lookup(local.globalSettings.addons.notifications, "email", 0) != 0 ? 1 : 0
  path  = lookup(local.globalSettings.addons.notifications, "email", 0) != 0 ? local.globalSettings.addons.notifications.email.vault_path : ""
}

resource "kubernetes_secret" "smtpNotification" {
  count = lookup(local.globalSettings.addons.notifications, "email", 0) != 0 ? 1 : 0
  metadata {
    name      = "email-notification"
    namespace = local.globalSettings.namespace
  }
  wait_for_service_account_token = true
  data = {
    "xpack.notification.email.account.gmail_account.smtp.secure_password" = data.vault_generic_secret.smtpNotification.0.data.gmail_account_smtp_secure_password
  }
}

locals {
  slackNotification = <<EOF
    xpack.notification.slack:
      account:
        monitoring:
          message_defaults:
            to: xpack
EOF
  emailNotification = <<EOF
    xpack.notification.email.account:
      gmail_account:
        profile: gmail
        smtp:
          auth: true
          starttls.enable: true
          host: smtp.gmail.com
          port: 587
          user: support@geminiadvisory.io
EOF
}
