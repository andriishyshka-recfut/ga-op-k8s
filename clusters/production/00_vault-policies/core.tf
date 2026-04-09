resource "vault_policy" "core" {
  name   = "core"
  policy = <<EOT
path "secret/data/minio/users" {
  capabilities = ["read","list"]
}
path "secret/data/elasticsearch-admin/*" {
  capabilities = ["read","list"]
}
path "secret/data/mongo/*" {
  capabilities = ["read","list"]
}
path "secret/data/captcha" {
  capabilities = ["read","list"]
}
path "secret/data/challenger" {
  capabilities = ["read","list"]
}
path "secret/data/core/*" {
  capabilities = ["read","list"]
}
path "secret/data/wl/core/*" {
  capabilities = ["read","list"]
}
path "secret/data/geo/*" {
  capabilities = ["read","list"]
}
path "secret/data/es-creds-compose-prod/*" {
  capabilities = ["read","list"]
}
path "secret/data/cppminion/*" {
  capabilities = ["read","list"]
}
path "secret/data/apm/*" {
  capabilities = ["read","list"]
}
path "secret/data/slack/auth" {
  capabilities = ["read","list"]
}
path "secret/data/slack/ka" {
  capabilities = ["read","list"]
}
path "secret/data/ching/*" {
  capabilities = ["read","list"]
}
path "secret/data/oidc_google_prod" {
  capabilities = ["read","list"]
}
path "secret/data/vortex/*" {
  capabilities = ["read","list"]
}
path "secret/data/core/auth/*" {
  capabilities = ["read","list","create","update"]
}
path "secret/data/wl/minifier/*" {
  capabilities = ["read","list"]
}
path "secret/data/mw/minio/sa/minifier_minifier" {
  capabilities = ["read","list"]
}
path "secret/data/mw/monitoring/otel" {
   capabilities = ["read","list"]
}
path "secret/data/misc/slack/app/ms-auth" {
   capabilities = ["read","list"]
}
path "secret/data/misc/slack/app/ms-w8" {
   capabilities = ["read","list"]
}
path "secret/data/misc/slack/app/ms-beep" {
   capabilities = ["read","list"]
}
EOT
}
