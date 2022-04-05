resource "tls_private_key" "clients_rsa_key" {
  for_each  = local.projects_setup_csr
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_cert_request" "clients_csr" {
  for_each        = local.projects_setup_csr
  private_key_pem = tls_private_key.clients_rsa_key[each.key].private_key_pem

  subject {
    common_name  = each.key
    organization = "GeminiAdvisory"
  }
  depends_on = [
    tls_private_key.clients_rsa_key
  ]
}

# Add var for role name
resource "vault_pki_secret_backend_sign" "clients" {
  for_each    = local.projects_setup_csr
  backend     = "pki_${each.key}"
  name        = each.key
  ttl         = 31522440
  csr         = tls_cert_request.clients_csr[each.key].cert_request_pem
  common_name = each.key
  depends_on = [
    tls_cert_request.clients_csr
  ]
}

resource "local_file" "tmp_json" {
  for_each = local.projects_setup_csr
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
  for_each = local.projects_setup_csr
  triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = "vault kv put secret/tls-proxy/certs/${each.key} @${each.key}.json"
  }
  depends_on = [
    local_file.tmp_json
  ]
}

resource "null_resource" "certs_installed" {
  for_each = local.projects_setup_csr
  triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = "vault kv patch secret/tls-proxy/projects/${each.key} crt_installed=true"
  }
  depends_on = [
    null_resource.certs
  ]
}

resource "kubernetes_manifest" "tls_proxy_cert" {
  for_each = local.project_data
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind"       = "Certificate"
    "metadata" = {
      "name"      = "${each.key}-cert"
      "namespace" = "istio-system"
    }
    "spec" = {
      "commonName" = each.value.domain
      "issuerRef" = {
        "kind" = "ClusterIssuer"
        "name" = each.value.cluster_issuer
      }
      "secretName" = "${each.key}-cert"
    }
  }
}

resource "kubernetes_manifest" "tls_proxy_gateway" {
  for_each = local.project_data
  manifest = {
    "apiVersion" = "networking.istio.io/v1beta1"
    "kind"       = "Gateway"
    "metadata" = {
      "name"      = "${each.key}-gateway"
      "namespace" = "istio-system"
    }
    "spec" = {
      "selector" = {
        "istio" = "ingressgateway-lb"
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
            "credentialName" = "${each.key}-cert"
            "mode"           = "MUTUAL"
          }
        }
      ]
    }
  }
}

resource "kubernetes_manifest" "tls_proxy_virtualservice_haproxy" {
  for_each = nonsensitive(local.projects_haproxy)
  manifest = {
    "apiVersion" = "networking.istio.io/v1beta1"
    "kind"       = "VirtualService"
    "metadata" = {
      "name"      = "${each.key}-virtualservice"
      "namespace" = each.value.namespace
    }
    "spec" = {
      "gateways" = [
        "istio-system/${each.key}-gateway",
      ]
      "hosts" = [
        each.value.domain
      ]
      "http" = [
        {
          "match" = [
            {
              "uri" = {
                "prefix" = "/"
              }
            },
          ]
          "route" = [
            {
              "destination" = {
                "host" = "basic-auth-proxy"
                "port" = {
                  "number" = 8080
                }
              }
            },
          ]
        },
      ]
    }
  }
}

resource "kubernetes_manifest" "tls_proxy_virtualservice_wo_haproxy" {
  for_each = nonsensitive(local.projects_wo_haproxy)
  manifest = {
    "apiVersion" = "networking.istio.io/v1beta1"
    "kind"       = "VirtualService"
    "metadata" = {
      "name"      = "${each.key}-virtualservice"
      "namespace" = each.value.namespace
    }
    "spec" = {
      "gateways" = [
        "istio-system/${each.key}-gateway",
      ]
      "hosts" = [
        each.value.domain
      ]
      "http" = [
        {
          "match" = [
            {
              "uri" = {
                "prefix" = "/"
              }
            },
          ]
          "route" = [
            {
              "destination" = {
                "host" = nonsensitive(each.value.destination_service)
                "port" = {
                  "number" = nonsensitive(each.value.destination_port)
                }
              }
            },
          ]
        },
      ]
    }
  }
}

resource "kubernetes_config_map" "haproxy_configmap" {
  for_each = nonsensitive(local.projects_haproxy)
  metadata {
    name      = "haproxy-config"
    namespace = each.value.namespace
  }
  data = {
    "haproxy.cfg" = <<EOF
userlist  clients
  ${local.auth_user_list[each.key]}
frontend auth
  mode  http
  bind  :8080
  http-request auth unless { http_auth(clients) }
  default_backend service
backend service
  mode  http
  server srv1 $SERVICE_HOST:$SERVICE_PORT
EOF
  }
}

resource "kubernetes_deployment" "basic_auth_proxy" {
  for_each = nonsensitive(local.projects_haproxy)
  metadata {
    name      = "basic-auth-proxy"
    namespace = each.value.namespace
    labels = {
      app = "basic-auth-proxy"
    }
  }
  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "basic-auth-proxy"
      }
    }

    template {
      metadata {
        labels = {
          app = "basic-auth-proxy"
        }
        annotations = {
          sidecar.istio.io / inject = "true"
        }
      }

      spec {
        volume {
          name = "haproxy-config"
          config_map {
            name = "haproxy-config"
          }
        }
        container {
          image = "haproxy:alpine"
          name  = "basic-auth-proxy"
          volume_mount {
            name       = "haproxy-config"
            mount_path = "/usr/local/etc/haproxy"
            read_only  = true
          }
          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
          }
          port {
            protocol       = "TCP"
            container_port = 8080
          }
          env {
            name  = "SERVICE_HOST"
            value = each.value.destination_service
          }
          env {
            name  = "SERVICE_PORT"
            value = each.value.destination_port
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "basic_auth_proxy" {
  for_each = nonsensitive(local.projects_haproxy)
  metadata {
    name      = "basic-auth-proxy"
    namespace = each.value.namespace
  }
  spec {
    selector = {
      app = "basic-auth-proxy"
    }
    port {
      port        = 8080
      target_port = 8080
    }
  }
}
