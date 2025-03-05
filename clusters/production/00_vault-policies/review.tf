resource "vault_policy" "review" {
  name   = "review"
  policy = <<EOT
path "secret/data/mongo/metaReviewMs" {
  capabilities = ["read","list"]
}
EOT
}
