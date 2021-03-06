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
