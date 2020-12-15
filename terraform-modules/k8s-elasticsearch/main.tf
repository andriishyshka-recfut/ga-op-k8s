

resource "helm_release" "elasticsearch" {
  name   = local.esValues.esName
  chart  = "${path.module}/elasticsearch"
  wait   = true
  atomic = true
  values = [
    yamlencode(local.esValues),
    yamlencode(local.oidcConfig)
  ]
  depends_on = [
    kubernetes_namespace.namespace,
    kubernetes_secret.gcs_credentials
  ]
}


resource "helm_release" "kibana" {
  name   = local.kibanaValues.name
  chart  = "${path.module}/kibana"
  wait   = true
  atomic = true
  values = [
    yamlencode(local.kibanaValues)
  ]
  depends_on = [
    null_resource.ansible_validate_resources
  ]
}

resource "null_resource" "ansible_validate_resources" {

  triggers = {
    playbook_contents = md5(file("${path.module}/../../ansible/validate_eck.yml"))
    helm_release      = helm_release.elasticsearch.id
  }
  provisioner "local-exec" {
    command = <<COMMAND
    cd ${path.module}/../../ansible &&\
    ansible-playbook validate_eck.yml \
      -e 'ansible_python_interpreter=/usr/bin/python3'
COMMAND
    environment = merge(local.ansibleEnvs, {
      name       = local.esValues.esName
      kind       = "Elasticsearch"
      apiVersion = "elasticsearch.k8s.elastic.co/v1"
    })
  }
  depends_on = [
    helm_release.elasticsearch
  ]
}

resource "null_resource" "ansible_validate_kibana" {

  triggers = {
    playbook_contents = md5(file("${path.module}/../../ansible/validate_eck.yml"))
    helm_release      = helm_release.kibana.id
  }
  provisioner "local-exec" {
    command = <<COMMAND
    cd ${path.module}/../../ansible &&\
    ansible-playbook validate_eck.yml \
      -e 'ansible_python_interpreter=/usr/bin/python3'
COMMAND
    environment = merge(local.ansibleEnvs, {
      name       = local.kibanaValues.name
      kind       = "Kibana"
      apiVersion = "kibana.k8s.elastic.co/v1beta1"
    })
  }
  depends_on = [
    helm_release.kibana
  ]
}


resource "kubernetes_namespace" "namespace" {
  count = local.createNs
  metadata {

    labels = {
      istio-injection = "enabled"
    }

    name = local.esValues.namespace
  }
}

resource "kubernetes_limit_range" "limit" {
  count = local.createNs
  metadata {
    name      = "default-limit-range"
    namespace = local.esValues.namespace
  }
  spec {
    limit {
      type = "Container"
      default_request = {
        cpu    = "10m"
        memory = "20Mi"
      }
    }
  }
}
resource "kubernetes_secret" "gcs_credentials" {
  metadata {
    name      = "gcs-credentials"
    namespace = local.esValues.namespace
  }

  data = {
    "gcs.client.default.credentials_file" = base64decode(var.BackupSaPrivateKey)
  }

  depends_on = [kubernetes_namespace.namespace]
  # type = "Opaque"
}
