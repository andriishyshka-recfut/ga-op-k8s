locals{
  gkeClusterEndpoint      = var.GkeClusterConnectionSettings.HOST
  gkeBearerToken          = var.GkeClusterConnectionSettings.API_KEY
}


resource "null_resource" "kubectl_apply_ingresses" {
  triggers = {
      lb-config = null_resource.ansible_bastion_playbook.id
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<COMMAND
    kubectl --server ${local.gkeClusterEndpoint}  \
     --token ${local.gkeBearerToken}  --insecure-skip-tls-verify=true \
     apply -f ${path.root}/ingresses
COMMAND
  }
  depends_on = [
  null_resource.ansible_bastion_playbook
  ]
}

resource "null_resource" "ansible_wait_for_cert" {

  triggers = {
    playbook_contents = md5(file("${path.module}/../../ansible/validate_eck.yml"))
    helm_release      = helm_release.elasticsearch.id
  }
  provisioner "local-exec" {
    command = <<COMMAND
    cd ${path.module}/../../ansible &&\
    ansible-playbook k8s-wait-for.yml \
      -e 'ansible_python_interpreter=/usr/bin/python3'
COMMAND
    environment = merge(local.ansibleEnvs, {
      name       = "vault-cert"
      kind       = "certificates"
      namespace  = "istio-system"
      apiVersion = "elasticsearch.k8s.elastic.co/v1"
      statusPath = "conditions.0.reason"
      requiredStatus = "Ready"
    })
  }
  depends_on = [
      null_resource.kubectl_apply_ingresses
  ]
}
