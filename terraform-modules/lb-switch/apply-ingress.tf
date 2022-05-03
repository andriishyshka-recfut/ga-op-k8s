

# resource "null_resource" "kubectl_apply_ingresses" {
#   triggers = {
#       lb-config = null_resource.ansible_bastion_playbook.id
#   }
#   provisioner "local-exec" {
#     interpreter = ["/bin/bash", "-c"]
#     command     = <<COMMAND
#     kubectl --server ${local.gkeClusterConnectionSettings.HOST}  \
#      --token ${local.gkeClusterConnectionSettings.API_KEY}  --insecure-skip-tls-verify=true \
#      apply -f ${path.root}/ingresses
# COMMAND
#   }
#   depends_on = [
#   null_resource.ansible_bastion_playbook
#   ]
# }
#
# resource "null_resource" "ansible_wait_for_cert" {
#
#   triggers = {
#     playbook_contents = md5(file("${path.module}/../../ansible/k8s-wait-for.yml"))
#     switchId = null_resource.ansible_bastion_playbook.id
#     ingressesId = null_resource.kubectl_apply_ingresses.id
#   }
#   provisioner "local-exec" {
#     command = <<COMMAND
#     cd ${path.module}/../../ansible &&\
#     ansible-playbook k8s-wait-for.yml
#
# COMMAND
#     environment = merge(local.ansibleEnvs, {
#       name       = "vault-cert"
#       kind       = "certificates"
#       namespace  = "istio-system"
#       apiVersion = "cert-manager.io/v1alpha2"
#       statusPath = "conditions[0].reason"
#       requiredStatus = "Ready"
#     })
#   }
#   depends_on = [
#       null_resource.kubectl_apply_ingresses
#   ]
# }
resource "kubernetes_manifest" "ingress_letsencrypt_cert" {
  for_each = local.ingressSettings
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
        each.value.domain,
      ]
      "issuerRef" = {
        "kind" = "ClusterIssuer"
        "name" = "letsencrypt-prod"
      }
      "secretName" = "${each.key}-cert"
    }
  }
}

resource "kubernetes_manifest" "ingress_gateway" {
  for_each = local.ingressSettings
  manifest = {
    "apiVersion" = "networking.istio.io/v1beta1"
    "kind"       = "Gateway"
    "metadata" = {
      "name"      = "${each.key}-wg-gateway"
      "namespace" = "istio-ingress"
    }
    "spec" = {
      "selector" = {
        "istio" = "ingressgateway"
      }
      "servers" = [
        # {
        #   "hosts" = [
        #     each.value.domain
        #   ]
        #   "port" = {
        #     "name"     = "http"
        #     "number"   = 80
        #     "protocol" = "HTTP"
        #   }
        #   "tls" = {
        #     "httpsRedirect" = "true"
        #   }
        # },
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
            "mode"           = "SIMPLE"
          }
        }
      ]
    }
  }
}

resource "kubernetes_manifest" "ingress_virtualservice" {
  for_each = local.ingressSettings
  manifest = {
    "apiVersion" = "networking.istio.io/v1beta1"
    "kind"       = "VirtualService"
    "metadata" = {
      "name"      = "${each.key}-virtualservice"
      "namespace" = each.value.namespace
    }
    "spec" = {
      "gateways" = [
        "istio-ingress/${each.key}-wg-gateway",
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
                "host" = each.value.service
                "port" = {
                  "number" = each.value.port
                }
              }
            },
          ]
        },
      ]
    }
  }
}
