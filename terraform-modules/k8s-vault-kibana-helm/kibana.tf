resource "random_password" "security_encryptionkey" {
  for_each = local.kibanaSettings
  length   = 48
  special  = false
}

resource "random_password" "reporting_encryptionkey" {
  for_each = local.kibanaSettings
  length   = 48
  special  = false
}

resource "random_password" "encryptedsavedobjects_encryptionkey" {
  for_each = local.kibanaSettings
  length   = 48
  special  = false
}


resource "helm_release" "kibana" {
  for_each  = local.kibanaSettings
  name      = "kibana-${each.key}"
  chart     = "${path.module}/charts/kibana"
  wait      = true
  atomic    = true
  timeout   = 600
  namespace = each.value.namespace
  values = [
    templatefile("${path.module}/kibana-values.tftpl", merge(local.globalSettings, each.value, { kibana_name = each.key, security_encryptionkey = random_password.security_encryptionkey[each.key].result, reporting_encryptionkey = random_password.reporting_encryptionkey[each.key].result, encryptedsavedobjects_encryptionkey = random_password.encryptedsavedobjects_encryptionkey[each.key].result }))
  ]
  depends_on = [
    kubernetes_job.kibana_user,
    kubernetes_secret.kibana_elastic_user
  ]
}
