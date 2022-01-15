
resource "helm_release" "kibana" {
  name   = local.kibanaValues.name
  namespace = local.esValues.namespace
  chart  = "${path.module}/kibana"
  wait   = true
  atomic = true
  values = [
    yamlencode(local.kibanaValues)
  ]
  set {
    name = "kibanaVersion"
    value = local.version
  }
  set {
    name = "oidc_provider.istio_gateway_fqdn"
    value = local.monUrl
  }
  depends_on = [
    null_resource.ansible_validate_resources
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
    ansible-playbook validate_eck.yml

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
