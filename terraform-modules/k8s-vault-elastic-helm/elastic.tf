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
  for_each  = local.nodePools
  name      = each.key
  chart     = "${path.module}/charts/elasticsearch8"
  wait      = true
  atomic    = false
  timeout   = 28800
  namespace = local.globalSettings.namespace
  values = [
    templatefile("${path.module}/elastic-values.tftpl", merge(each.value, { globalSettings = local.globalSettings }, local.combineSettings, { nodePool = each.key }))
  ]
  set = [
  {
    name  = "imageTag"
    value = local.globalSettings.imageTag
  },
  {
    name  = "nodeGroup"
    value = each.key
  },
  {
    name  = "minimumMasterNodes"
    value = 1
  }
  ]
  depends_on = [
    kubernetes_secret.elastic_secret,
    kubernetes_persistent_volume_claim.elasticsearch,
    kubernetes_secret.keystores,
    kubernetes_config_map.reboot_date
  ]
}

