

resource "helm_release" "elasticsearch" {
  name   = local.esValues.esName
  namespace = local.esValues.namespace
  chart  = "${path.module}/elasticsearch"
  wait   = true
  atomic = true
  values = [
    yamlencode(local.esValues),
    yamlencode(local.oidcConfig)
  ]
  set =[{
    name = "appVersion"
    value = local.version
  }]
}

resource "null_resource" "ansible_validate_resources" {

  triggers = {
    playbook_contents = md5(file("${path.module}/../../ansible/validate_eck.yml"))
    helm_release      = helm_release.elasticsearch.id
  }
  provisioner "local-exec" {
    command = <<COMMAND
    cd ${path.module}/../../ansible &&\
    ansible-playbook validate_eck.yml

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
