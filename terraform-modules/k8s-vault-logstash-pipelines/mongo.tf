resource "kubectl_manifest" "mongo_secretstore" {
  yaml_body  = templatefile("${path.module}/../../templates/external-secrets/SecretStore.tftpl", 
  {  values = { namespace = "elastic", cluster = var.Cluster, color = var.Color ,vault_url = local.vault_url }}
  )
}

resource "kubectl_manifest" "mongo_secret" {
  yaml_body  = templatefile("${path.module}/../../templates/external-secrets/ExternalSecret.tftpl", 
  { values = { namespace = "elastic", name = "mongo-credentials", secret_name = "mongo-credentials",vault_path = "red/mw/logstash/mongo"}}
  )
}