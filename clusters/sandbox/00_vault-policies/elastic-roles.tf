resource "vault_pki_secret_backend_role" "elastic" {
  backend            = "pki-elastic-int"
  name               = "elastic"
  issuer_ref         = "default"
  allow_ip_sans      = false
  key_type           = "rsa"
  key_bits           = 2048
  allow_localhost    = false
  allowed_domains    = ["mon-es-http", "mon-es-http.monitoring.svc", "elastic*-coor.*.svc.cluster.local"]
  allow_subdomains   = true
  allow_bare_domains = true
  allow_glob_domains = true
  allow_any_name     = false
  ou                 = ["Gemini"]
  organization       = ["Recorded Future"]
}


resource "vault_pki_secret_backend_role" "transport" {
  backend            = "pki-elastic-int"
  name               = "transport"
  issuer_ref         = "default"
  allow_ip_sans      = false
  key_type           = "rsa"
  key_bits           = 2048
  allow_localhost    = false
  allowed_domains    = ["*.elastic*.*.svc.cluster.local","elastic*.*.svc.cluster.local"]
  allow_subdomains   = true
  allow_bare_domains = true
  allow_glob_domains = true
  allow_any_name     = false
  ou                 = ["Gemini"]
  organization       = ["Recorded Future"]
}


resource "vault_policy" "elastic" {
  name = "elastic"

  policy = <<EOT
path "pki-elastic-int/sign/*" {
  capabilities = ["create", "update"]
}
EOT
}