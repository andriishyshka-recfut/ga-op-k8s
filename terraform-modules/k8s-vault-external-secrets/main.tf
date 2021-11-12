
resource "helm_release" "external_secrets" {
  name = "external-secrets"
  #chart = "${path.module}/umbrella-vault"
  chart      = "kubernetes-external-secrets"
  repository = "https://external-secrets.github.io/kubernetes-external-secrets/"
  #version           = "0.1.0"
  namespace         = "external-secrets"
  dependency_update = "true"
  values = [
    file("${path.module}/values.yaml")
  ]
}
