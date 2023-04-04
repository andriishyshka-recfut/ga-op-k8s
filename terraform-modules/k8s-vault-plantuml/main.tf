resource "helm_release" "plantuml" {
  for_each = var.plantuml_list
  repository = "https://stevehipwell.github.io/helm-charts/"
  chart = "plantuml"
  name  = "plantuml-${each.key}"
  namespace = local.namespace
  timeout   = 600
  wait      = true
  atomic    = true
  version = "3.20.0"
  values = [
    templatefile("${path.module}/plantuml-values.tftpl", merge(local.plantuml_values, {plantuml-name = each.key}))
  ]
}
