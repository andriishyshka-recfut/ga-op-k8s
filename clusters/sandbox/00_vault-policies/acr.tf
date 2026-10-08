resource "vault_policy" "acr" {
  name = "acr"

  policy = <<EOT
path "secret/data/mw/monitoring/otel" {
   capabilities = ["read","list"]
}
path "secret/data/mongo/*" {
   capabilities = ["read","list"]
}
path "secret/data/acr/*" {
   capabilities = ["read","list"]
}
path "secret/data/elasticsearch-admin/elastic7-v2" {
   capabilities = ["read","list"]
}
path "secret/data/telegram/os3/minio-attachment" {
   capabilities = ["read","list"]
}
path "secret/data/wl/acr/*" {
   capabilities = ["read","list"]
}
EOT
}