
resource "null_resource" "kubectl_transfer_vault" {
  triggers = {
      lb-config = null_resource.ansible_bastion_playbook.id
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<COMMAND
    kubectl --server ${local.gkeClusterConnectionSettings.HOST}  \
     --token ${local.gkeClusterConnectionSettings.API_KEY}  --insecure-skip-tls-verify=true \
     scale -n vault statefulset/vault --replicas=3
    kubectl --server ${local.inActiveGkeEndpoint}  \
     --token ${local.gkeClusterConnectionSettings.API_KEY}  --insecure-skip-tls-verify=true \
     scale -n vault statefulset/vault --replicas=0
COMMAND
  }
  depends_on = [
  null_resource.ansible_bastion_playbook
  ]
}
