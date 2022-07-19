
resource "null_resource" "deploy_tekton" {

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<COMMAND
    set -x
    kubectl apply --server ${local.gkeClusterEndpoint}  \
     --token ${local.gkeBearerToken}  \
     --insecure-skip-tls-verify=true  \
     -f https://storage.googleapis.com/tekton-releases/operator/latest/release.yaml && sleep 30 && \
    kubectl apply --server ${local.gkeClusterEndpoint}  \
     --token ${local.gkeBearerToken}  \
     --insecure-skip-tls-verify=true  \
     --filename https://raw.githubusercontent.com/tektoncd/operator/main/config/crs/kubernetes/config/all/operator_v1alpha1_config_cr.yaml
COMMAND
  }

}
