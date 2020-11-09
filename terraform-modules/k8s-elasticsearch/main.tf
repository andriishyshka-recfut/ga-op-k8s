

resource "helm_release" "elasticsearch" {
  name   = local.es_values.esName
  chart  = "${path.module}/elasticsearch"
  wait   = true
  atomic = true
  values = [
    yamlencode(local.es_values)
  ]
  depends_on = [
    kubernetes_namespace.namespace,
    kubernetes_secret.gcs-credentials
  ]
}


resource "helm_release" "kibana" {
  name   = local.kibana_values.name
  chart  = "${path.module}/kibana"
  wait   = true
  atomic = true
  values = [
    yamlencode(local.kibana_values)
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
    environment = merge(local.ansible_envs, {
      name       = local.es_values.esName
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
    environment = merge(local.ansible_envs, {
      name       = local.kibana_values.name
      kind       = "Kibana"
      apiVersion = "kibana.k8s.elastic.co/v1beta1"
    })
  }
  depends_on = [
    helm_release.kibana
  ]
}


resource "kubernetes_namespace" "namespace" {
  count = local.create_ns
  metadata {

    labels = {
      istio-injection = "enabled"
    }

    name = local.es_values.namespace
  }
}

resource "kubernetes_secret" "gcs-credentials" {
  metadata {
    name      = "gcs-credentials"
    namespace = local.es_values.namespace
  }

  data = {
    "gcs.client.default.credentials_file" = base64decode(var.backup_sa_private_key)
  }

  depends_on = [kubernetes_namespace.namespace]
  # type = "Opaque"
}
