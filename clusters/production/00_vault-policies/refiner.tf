resource "vault_policy" "refiner" {
  name   = "ching"
  policy = <<EOT
path "/secret/data/mw/monitoring/otel" {
  capabilities = ["read","list"]
}

EOT
}