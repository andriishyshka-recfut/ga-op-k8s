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
xpack.reporting.capture.browser.chromium.disableSandbox: true
xpack.security.audit.enabled: "true"
xpack.security.encryptionKey: "${data.vault_generic_secret.xpackSecurity.0.data.securityEncryptionKey}"
xpack.reporting.encryptionKey: "${data.vault_generic_secret.xpackSecurity.0.data.reportingEncryptionKey}"
xpack.encryptedSavedObjects.encryptionKey: "${data.vault_generic_secret.xpackSecurity.0.data.encryptedSavedObjectsEncryptionKey}"
xpack.security.cookieName: "sid"
# xpack.security.cookieName: "${data.vault_generic_secret.xpackSecurity.0.data.securityCookieName}"
savedObjects.maxImportPayloadBytes: "52428800"
savedObjects.maxImportExportSize: "100000"
server.ssl.supportedProtocols: ["TLSv1.2","TLSv1.3"]
server.publicBaseUrl: "https://k.regemini.com"
xpack.reporting.roles.enabled: false
xpack.reporting.index: ".reporting-re"
xpack.task_manager.index: ".kibana_task_manager-re"
EOF
  xpackConfig = local.xpackSecurity == 1 ? { "xpack_config" = local.configXpack } : { "xpack_config" = "" }
}