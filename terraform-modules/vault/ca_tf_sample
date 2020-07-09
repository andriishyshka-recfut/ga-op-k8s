resource "tls_private_key" "example" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}


resource "tls_self_signed_cert" "example" {
  key_algorithm   = "ECDSA"
  private_key_pem = tls_private_key.example.private_key_pem


  is_ca_certificate = true
  subject {
    common_name  = "example.cert"
    organization = "ACME Examples, Inc"
  }

  validity_period_hours = 168

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "cert_signing",
    "ocsp_signing"
  ]
}


resource "kubernetes_secret" "example" {
  metadata {
    name      = "basic-ca"
    namespace = "istio-system"
  }

  data = {
    "tls.key" = tls_private_key.example.private_key_pem
    "tls.crt" = tls_self_signed_cert.example.cert_pem
  }

  type = "kubernetes.io/tls"
}
