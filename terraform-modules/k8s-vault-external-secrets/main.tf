resource "helm_release" "external_secrets" {
  name       = "external-secrets"
  chart      = "external-secrets"
  repository = "https://charts.external-secrets.io"
  namespace  = "external-secrets"
  wait       = true
  atomic     = true
  version    = var.Settings.clusters[var.Cluster].versions.external-secrets.helm_version
  # dependency_update = "true"
  values = [
    file("${path.module}/values.yaml")
  ]
}

resource "helm_release" "external_secret_secretstore" {
  name      = "secretstore"
  chart     = "${path.module}/charts/secretstore"
  namespace = "external-secrets"
  wait      = true
  atomic    = true
  set {
    name  = "mountPath"
    value = "k8s-${var.Cluster}-${var.Color}"
  }
  dynamic "set" {
    for_each = local.namespaces
    content {
      name  = "namespaces[${set.key}]"
      value = set.value
    }
  }
  depends_on = [helm_release.external_secrets]
}

resource "kubectl_manifest" "external_secrets_store" {
  for_each   = toset(var.Color == "red" ? local.red_namespaces : local.namespaces)
  yaml_body  = templatefile("${path.module}/templates/SecretStore.tftpl", { namespace = each.key, cluster = var.Cluster, color = var.Color })
  depends_on = [time_sleep.wait_180_seconds]
}

# resource "kubernetes_manifest" "external_secrets_store" {
#   for_each = toset(var.Color == "red" ? local.red_namespaces : local.namespaces)
#   manifest = {
#     "apiVersion" = "external-secrets.io/v1"
#     "kind"       = "SecretStore"
#     "metadata" = {
#       "name"      = "vault-backend"
#       "namespace" = each.key
#     }
#     "spec" = {
#       "provider" = {
#         "vault" = {
#           "auth" = {
#             "kubernetes" = {
#               "mountPath" = "k8s-${var.Cluster}-${var.Color}"
#               "role"      = "external-secrets"
#             }
#           }
#           "server"  = "http://vault-active.vault:8200"
#           "version" = "v2"
#         }
#       }
#     }
#   }
#   depends_on = [
#     time_sleep.wait_180_seconds
#   ]
# }


resource "time_sleep" "wait_180_seconds" {
  create_duration = "180s"
}
