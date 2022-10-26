data "vault_generic_secret" "xpackSecurity" {
  count = local.xpackSecurity
  path  = local.kibanaValues.xpack_security.vault_path
}

locals {
  configXpack = <<EOF
xpack.security.authc.providers:
  oidc.Google:
    order: 1
    realm: google
  basic.basic1:
    order: 2
xpack.reporting.capture.browser.chromium.disableSandbox: "true"
xpack.security.audit.enabled: "true"
xpack.security.encryptionKey: "${data.vault_generic_secret.xpackSecurity.0.data.securityEncryptionKey}"
xpack.reporting.encryptionKey: "${data.vault_generic_secret.xpackSecurity.0.data.reportingEncryptionKey}"
xpack.encryptedSavedObjects.encryptionKey: "${data.vault_generic_secret.xpackSecurity.0.data.encryptedSavedObjectsEncryptionKey}"
xpack.security.cookieName: "sid"
xpack.security.session.idleTimeout: "10h"
xpack.security.session.lifespan: "7d"
xpack.security.session.cleanupInterval: "1d"
xpack.security.sessionTimeout: "10h"
elasticsearch.requestTimeout: "10h"
savedObjects.maxImportPayloadBytes: "52428800"
savedObjects.maxImportExportSize: "100000"
server.ssl.supportedProtocols: ["TLSv1.2","TLSv1.3"]
server.publicBaseUrl: "https://${local.kibanaValues.istio_gateway_fqdn}"
xpack.reporting.roles.enabled: false
xpack.reporting.index: ".reporting-re"
xpack.task_manager.index: ".kibana_task_manager-re"
monitoring.kibana.collection.enabled: "false"
monitoring.ui.container.elasticsearch.enabled: "true"
EOF
  xpackConfig = local.xpackSecurity == 1 ? { "xpack_config" = local.configXpack } : { "xpack_config" = "" }
}