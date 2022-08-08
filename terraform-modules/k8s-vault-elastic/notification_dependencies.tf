data "vault_generic_secret" "slackNotification" {
  count = local.slackNotificationSetup
  path  = local.esValues.slack_notification.vault_path
}

resource "kubernetes_secret" "slackNotification" {
  count = local.slackNotificationSetup
  metadata {
    name      = local.esValues.slack_notification.secret_name
    namespace = local.esValues.namespace
  }
  data = {
    "xpack.notification.slack.account.monitoring.secure_url" = data.vault_generic_secret.slackNotification.0.data.slack_account_monitoring_secure_url
  }
}

data "vault_generic_secret" "smtpNotification" {
  count = local.smtpNotificationSetup
  path  = local.esValues.smtp_notification.vault_path
}

resource "kubernetes_secret" "smtpNotification" {
  count = local.smtpNotificationSetup
  metadata {
    name      = local.esValues.smtp_notification.secret_name
    namespace = local.esValues.namespace
  }

  data = {
    "xpack.notification.email.account.gmail_account.smtp.secure_password" = data.vault_generic_secret.smtpNotification.0.data.gmail_account_smtp_secure_password
  }
}

locals {
  configNotification = <<EOF
xpack.notification.slack:
  account:
    monitoring:
      message_defaults:
        to: xpack
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
  notificationConfig = local.smtpNotificationSetup == 1 ? { "notification_config" = local.configNotification } : { "notification_config" = "" }
}
