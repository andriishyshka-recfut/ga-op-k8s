

resource "null_resource" "kubectl_apply_ingresses" {
  triggers = {
      lb-config = null_resource.ansible_bastion_playbook.id
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<COMMAND
    kubectl --server ${local.gkeClusterConnectionSettings.HOST}  \
     --token ${local.gkeClusterConnectionSettings.API_KEY}  --insecure-skip-tls-verify=true \
     apply -f ${path.root}/ingresses
COMMAND
  }
  depends_on = [
  null_resource.ansible_bastion_playbook
  ]
}

resource "null_resource" "ansible_wait_for_cert" {

  triggers = {
    playbook_contents = md5(file("${path.module}/../../ansible/k8s-wait-for.yml"))
    switchId = null_resource.ansible_bastion_playbook.id
    ingressesId = null_resource.kubectl_apply_ingresses.id
  }
  provisioner "local-exec" {
    command = <<COMMAND
    cd ${path.module}/../../ansible &&\
    ansible-playbook k8s-wait-for.yml

COMMAND
    environment = merge(local.ansibleEnvs, {
      name       = "vault-cert"
      kind       = "certificates"
      namespace  = "istio-system"
      apiVersion = "cert-manager.io/v1alpha2"
      statusPath = "conditions[0].reason"
      requiredStatus = "Ready"
    })
  }
  depends_on = [
      null_resource.kubectl_apply_ingresses
  ]
}
