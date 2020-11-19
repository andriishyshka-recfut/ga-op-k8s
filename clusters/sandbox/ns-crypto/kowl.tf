resource "helm_release" "kowl" {
  name = "kowl"

  chart      = "kowl"
  repository = "https://raw.githubusercontent.com/cloudhut/charts/master/archives"
  #version           = "0.1.0"
  namespace         = local.ns
  dependency_update = "true"

  values = [
    file("kowl_values.yaml")
  ]

  depends_on = [
    kubernetes_namespace.ns

  ]
}
