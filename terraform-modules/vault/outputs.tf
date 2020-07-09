# output "vault_ca_certificate" {
#   value = tls_self_signed_cert.example.cert_pem
# }
# Path vault_addr after ansible unseal playbook completion
output "vault_addr" {
  value = "https://vault.${var.cluster}.${var.settings.cluster_settings[var.cluster].domain}"
}
output "vault_unsealed" {
  value = length(null_resource.ansible_vault_playbook.id) > 0 ? true : false
}
