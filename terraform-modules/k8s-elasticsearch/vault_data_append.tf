data "kubernetes_secret" "es_password" {
  count = local.storeEsPasswordInVault
  # provider = kubernetes.kubernetes
  metadata {
    name      = "${local.esValues.esName}-es-elastic-user"
    namespace = local.esValues.namespace
  }
  depends_on = [helm_release.elasticsearch]
}
resource "vault_generic_secret" "example" {
  count = local.storeEsPasswordInVault
  path  = "secret/elasticsearch-admin/${local.esValues.esName}"

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
