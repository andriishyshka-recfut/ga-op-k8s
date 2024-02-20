resource "null_resource" "pki_enable" {
  for_each = nonsensitive(local.project_setup_pki)
  triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = "vault secrets enable -path=pki-${each.key} pki"
  }
}

resource "null_resource" "pki_init_settings" {
  for_each = nonsensitive(local.project_setup_pki)
  triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = "vault secrets tune -max-lease-ttl=158544000 pki-${each.key}"
  }
  depends_on = [
    null_resource.pki_enable
  ]
}

resource "null_resource" "pki_generate_root" {
  for_each = nonsensitive(local.project_setup_pki)
  triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = <<-EOT
      vault write pki-${each.key}/root/generate/internal common_name=regemini.com ttl=158544000 \
      ou=IT organization="Gemini Advisory LLC" \
      country=US locality=Miami province=FL
    EOT
  }
  depends_on = [
    null_resource.pki_init_settings
  ]
}

resource "null_resource" "pki_setup_role" {
  for_each = nonsensitive(local.project_setup_pki)
  triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = <<-EOT
      vault write pki-${each.key}/roles/${each.key} max_ttl=32832000 allow_localhost=true \
      allowed_domains=${each.value.domain} allow_bare_domains=true allow_subdomains=true \
      allow_wildcard_certificates=true ou=IT organization="Gemini Advisory LLC"
    EOT
  }
  depends_on = [
    null_resource.pki_generate_root
  ]
}

resource "null_resource" "pki_installed" {
  for_each = nonsensitive(local.project_setup_pki)
  triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = "vault kv patch secret/${var.SecretPath}/projects/${each.key} pki_installed=true"
  }
  depends_on = [
    null_resource.pki_setup_role
  ]
}


resource "kubernetes_manifest" "vault_certmanager" {
  for_each = local.projects
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind"       = "ClusterIssuer"
    "metadata" = {
      "name" = "vault-${each.key}-issuer"
    }
    "spec" = {
      "vault" = {
        "auth" = {
          "kubernetes" = {
            "mountPath" = "/v1/auth/k8s-${var.Cluster}-${var.Color}"
            "role"      = "cert-manager"
            "secretRef" = {
              "key"  = "token"
              "name" = "sa-${var.Cluster}-cert-manager"
            }
          }
        }
        "path"   = "pki-${each.key}/sign/${each.key}"
        "server" = var.VaultAddress
      }
    }
  }
}

resource "tls_private_key" "clients_rsa_key" {
  for_each  = nonsensitive(local.projects_setup_csr)
  algorithm = "RSA"
  rsa_bits  = lookup(each.value, "rsa_length", 4096)
}

resource "tls_cert_request" "clients_csr" {
  for_each        = nonsensitive(local.projects_setup_csr)
  private_key_pem = tls_private_key.clients_rsa_key[each.key].private_key_pem

  subject {
    common_name  = each.value.domain
    organization = "Gemini Advisory"
  }
  depends_on = [
    tls_private_key.clients_rsa_key
  ]
}

# Add var for role name
resource "vault_pki_secret_backend_sign" "clients" {
  for_each    = nonsensitive(local.projects_setup_csr)
  backend     = "pki-${each.key}"
  name        = each.key
  ttl         = 31522440
  csr         = tls_cert_request.clients_csr[each.key].cert_request_pem
  common_name = each.value.domain
  depends_on = [
    tls_cert_request.clients_csr
  ]
}

resource "local_file" "tmp_json" {
  for_each = nonsensitive(local.projects_setup_csr)
  filename = "${each.key}.json"
  content = jsonencode({
    "key"        = tls_private_key.clients_rsa_key[each.key].private_key_pem
    "cert"       = vault_pki_secret_backend_sign.clients[each.key].certificate,
    "ca"         = vault_pki_secret_backend_sign.clients[each.key].issuing_ca,
    "serial"     = vault_pki_secret_backend_sign.clients[each.key].serial,
    "expiration" = tostring(vault_pki_secret_backend_sign.clients[each.key].expiration)
  })
  depends_on = [
    vault_pki_secret_backend_sign.clients
  ]
}

resource "null_resource" "certs" {
  for_each = nonsensitive(local.projects_setup_csr)
  triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = "vault kv put secret/${var.SecretPath}/certs/${each.key} @${each.key}.json"
  }
  depends_on = [
    local_file.tmp_json
  ]
}

resource "null_resource" "certs_installed" {
  for_each = nonsensitive(local.projects_setup_csr)
  triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = "vault kv patch secret/${var.SecretPath}/projects/${each.key} crt_installed=true"
  }
  depends_on = [
    null_resource.certs
  ]
}

resource "kubernetes_manifest" "tls_proxy_cert" {
  for_each = nonsensitive(local.project_data_enabled)
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind"       = "Certificate"
    "metadata" = {
      "name"      = "${each.key}-cert"
      "namespace" = "istio-ingress"
    }
    "spec" = {
      "commonName" = each.value.domain
      "dnsNames" = [
        each.value.domain
      ]
      "duration"    = "1080h0m0s"
      "renewBefore" = "360h0m0s"
      "issuerRef" = {
        "kind" = "ClusterIssuer"
        "name" = lookup(each.value, "cluster_issuer", "vault-${each.key}-issuer")
      }
      "secretName" = "${each.key}-cert"
    }
  }
}

resource "kubernetes_manifest" "tls_proxy_gateway" {
  for_each = nonsensitive(local.project_data_enabled)
  manifest = {
    "apiVersion" = "networking.istio.io/v1beta1"
    "kind"       = "Gateway"
    "metadata" = {
      "name"      = "${each.key}-gateway"
      "namespace" = "istio-ingress"
    }
    "spec" = {
      "selector" = {
        "istio" = lookup(each.value, "ingress", "ingressgateway-lb")
      }
      "servers" = [
        {
          "hosts" = [
            each.value.domain
          ]
          "port" = {
            "name"     = "http"
            "number"   = 80
            "protocol" = "HTTP"
          }
          "tls" = {
            "httpsRedirect" = "true"
          }
        },
        {
          "hosts" = [
            each.value.domain
          ]
          "port" = {
            "name"     = "https"
            "number"   = 443
            "protocol" = "HTTPS"
          }
          "tls" = {
            "credentialName"     = "${each.key}-cert"
            "minProtocolVersion" = lookup(each.value, "minimum_tls_version", "TLSV1_3")
            "mode"               = "MUTUAL"
          }
        }
      ]
    }
  }
}

resource "kubernetes_manifest" "tls_proxy_virtualservice" {
  for_each = nonsensitive(local.project_data_enabled)
  manifest = yamldecode(templatefile("${path.module}/virtualservice.yaml.tftpl", { "project_name" : each.key, "project_data" : each.value, "basic_auth" : local.auth_user_list }))
}



