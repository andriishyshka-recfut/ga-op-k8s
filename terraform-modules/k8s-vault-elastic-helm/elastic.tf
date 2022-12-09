resource "random_password" "elastic_password" {
  length  = 24
  special = false
}

resource "kubernetes_secret" "elastic_secret" {
  metadata {
    name      = "elastic-credentials"
    namespace = local.globalSettings.namespace
  }
  data = {
    "elastic" = random_password.elastic_password.result
  }
  depends_on = [
    random_password.elastic_password
  ]
}

resource "helm_release" "elastic" {
  depends_on = [
    kubernetes_secret.elastic_secret
  ]
  for_each  = local.nodePools
  name      = each.key
  chart     = "${path.module}/charts/elasticsearch"
  wait      = true
  atomic    = true
  timeout   = 7200
  namespace = local.globalSettings.namespace
  values = [
    templatefile("${path.module}/elastic-values.tftpl", merge(each.value, local.globalSettings, local.combineSettings, { nodePool = each.key }))
  ]
  set {
    name  = "imageTag"
    value = local.globalSettings.imageTag
  }
  set {
    name  = "nodeGroup"
    value = each.key
  }
  set {
    name  = "minimumMasterNodes"
    value = 1
  }
}

