data "vault_generic_secret" "xpackSecurity" {
  count = local.xpackSecurity
  path  = local.kibanaValues.xpack_security.vault_path
}

locals {
  configXpack = <<EOF
        
xpack.reporting.capture.browser.chromium.disableSandbox: true
xpack.security.audit.enabled: "true"
xpack.security.encryptionKey: ${data.vault_generic_secret.xpackSecurity.0.data.securityEncryptionKey}
xpack.reporting.encryptionKey: ${data.vault_generic_secret.xpackSecurity.0.data.reportingEncryptionKey}
xpack.encryptedSavedObjects.encryptionKey: ${data.vault_generic_secret.xpackSecurity.0.data.encryptedSavedObjectsEncryptionKey}
xpack.security.cookieName: ${data.vault_generic_secret.xpackSecurity.0.data.securityCookieName}
                        
EOF
  xpackConfig = local.xpackSecurity == 1 ? { "xpack_config" = local.configXpack } : { "xpack_config" = "" }
}