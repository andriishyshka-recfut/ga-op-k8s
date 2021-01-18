
resource "null_resource" "patch_storage_class" {

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<COMMAND
    kubectl patch --server ${local.gkeClusterEndpoint}  \
     --token ${local.gkeBearerToken}  \
     --insecure-skip-tls-verify=true  \
     storageclass standard -p \
     '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
    kubectl patch --server ${local.gkeClusterEndpoint}  \
     --token ${local.gkeBearerToken}  \
     --insecure-skip-tls-verify=true  \
     storageclass standard-rwo -p \
     '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
COMMAND
  }

}
