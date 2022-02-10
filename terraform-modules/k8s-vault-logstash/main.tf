data "kubernetes_secret" "pipeline_ca" {
  for_each = local.namespaces
  metadata {
    name      = "${each.value.es_name}-es-cert"
    namespace = each.key
  }
}


resource "kubernetes_secret" "pipeline_ca" {
  for_each = data.kubernetes_secret.pipeline_ca
  metadata {
    name      = "${each.key}-es-cert"
    namespace = "logstash"
  }
  data = each.value.data
}

data "kubernetes_secret" "pipeline_pass" {
  for_each = local.namespaces
  metadata {
    name      = "${each.value.es_name}-es-elastic-user"
    namespace = each.key
  }
}

resource "kubernetes_secret" "pipeline_pass" {
  for_each = data.kubernetes_secret.pipeline_pass
  metadata {
    name      = "${each.key}-es-elastic-user"
    namespace = "logstash"
  }
  data = each.value.data
}

resource "helm_release" "logstash" {
  name       = "logstash"
  namespace  = "logstash"
  repository = "https://helm.elastic.co"
  chart      = "logstash"
  wait       = true
  atomic     = true
  timeout    = 300
  values = [
    file("${path.module}/logstash-values.yaml")
  ]
  # set {
  #   name = "kibanaVersion"
  #   value = local.version
  # }

  # depends_on = [
  #   null_resource.ansible_validate_resources
  # ]
}
