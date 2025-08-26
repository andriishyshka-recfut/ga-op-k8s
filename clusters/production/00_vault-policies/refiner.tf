resource "vault_policy" "refiner" {
  name   = "refiner"
  policy = <<EOT
path "/secret/data/mw/monitoring/otel" {
  capabilities = ["read","list"]
}

EOT
}