resource "kubectl_manifest" "mongo_secretstore" {
  count = var.Color == "red" ? 1 : 0
  yaml_body  = templatefile("${path.module}/../../templates/external-secrets/SecretStore.tftpl", 
  {  values = { namespace = "elastic", cluster = var.Cluster, color = var.Color ,vault_url = local.vault_url }}
  )
}

resource "kubectl_manifest" "mongo_secret" {
  count = var.Color == "red" ? 1 : 0
  yaml_body  = templatefile("${path.module}/../../templates/external-secrets/ExternalSecret.tftpl", 
  { values = { namespace = "elastic", name = "mongo-credentials", secret_name = "mongo-credentials",vault_path = "red/mw/logstash/mongo"}}
  )
}