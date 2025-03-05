resource "vault_policy" "prometheus_metrics" {
  name   = "prometheus-metrics"
  policy = <<EOT
path "/sys/metrics" {
  capabilities = ["read"]
}
EOT
}
