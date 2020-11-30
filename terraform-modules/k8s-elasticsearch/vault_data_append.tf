data "kubernetes_secret" "es_password" {
  count = local.store_es_password_in_vault
  # provider = kubernetes.kubernetes
  metadata {
    name      = "${local.es_values.esName}-es-elastic-user"
    namespace = local.es_values.namespace
  }
  depends_on = [helm_release.elasticsearch]
}
resource "vault_generic_secret" "example" {
  count = local.store_es_password_in_vault
  path  = "secret/elasticsearch-admin/${local.es_values.esName}"

  data_json = <<EOT
{
  "username":   "elastic",
  "password": "${data.kubernetes_secret.es_password[0].data.elastic}"
}
EOT
}
# output "creds" {
#   value = "elastic:${data.kubernetes_secret.es_password.data.elastic}"
# }
