resource "null_resource" "deploy_tekton" {

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<COMMAND
    set -x
    kubectl --server ${local.gkeClusterEndpoint}  \
     --token ${local.gkeBearerToken}  \
     --insecure-skip-tls-verify=true  \
    create namespace ${local.tektonNs} && \
    kubectl apply --server ${local.gkeClusterEndpoint}  \
     --token ${local.gkeBearerToken}  \
     --insecure-skip-tls-verify=true  \
     -f https://storage.googleapis.com/tekton-releases/operator/latest/release.yaml && sleep 30 && \
     kubectl --server ${local.gkeClusterEndpoint}  \
     --token ${local.gkeBearerToken}  \
     --insecure-skip-tls-verify=true  \
     --namespace=${local.tektonNs}  \
     create configmap cluster-settings --from-literal=cluster=${var.Cluster} --from-literal=color=${var.Color} --from-literal=configPath=${local.configPath} \
     --from-literal=vaultAddr=${var.VaultAddress} && \
     kubectl --server ${local.gkeClusterEndpoint}  \
     --token ${local.gkeBearerToken}  \
     --insecure-skip-tls-verify=true  \
     --namespace=${local.tektonMainNs}  \
     create configmap cluster-settings --from-literal=cluster=${var.Cluster} --from-literal=color=${var.Color} --from-literal=configPath=${local.configPath} \
     --from-literal=vaultAddr=${var.VaultAddress}
COMMAND
  }

}

resource "null_resource" "harbor_creds" {

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<COMMAND
    set -x
    export VAULT_ADDR=${var.VaultAddress}
    kubectl --server ${local.gkeClusterEndpoint} \
     --token ${local.gkeBearerToken}  \
     --insecure-skip-tls-verify=true  \
     create secret docker-registry harbor --docker-server=harbor.regemini.io \
      --docker-username=$(vault kv get -field=user secret/goharbor/docker_login) \
      --docker-password=$(vault kv get -field=password secret/goharbor/docker_login) \
    --namespace=${local.tektonNs} && sleep 30 && \
    kubectl patch --server ${local.gkeClusterEndpoint}  \
     --token ${local.gkeBearerToken}  \
     --insecure-skip-tls-verify=true  \
     --namespace=${local.tektonNs}  \
     serviceaccount default -p '{"imagePullSecrets": [{"name": "harbor"}]}' && sleep 30 && \
    kubectl patch --server ${local.gkeClusterEndpoint}  \
     --token ${local.gkeBearerToken}  \
     --insecure-skip-tls-verify=true  \
     --namespace="tekton-pipelines \
    configmap config-defaults -p 



     {"imagePullSecrets":[{"name":"harbor"}],"affinity":{"nodeAffinity":{"requiredDuringSchedulingIgnoredDuringExecution":{"nodeSelectorTerms":[{"matchExpressions":[{"key":"workloadsType","operator":"In","values":["tekton"]}]}]}}},"tolerations":[{"key":"workloadsType","operator":"Equal","value":"tekton","effect":"NoSchedule"},{"key":"node.kubernetes.io/not-ready","operator":"Exists","effect":"NoExecute","tolerationSeconds":300},{"key":"node.kubernetes.io/unreachable","operator":"Exists","effect":"NoExecute","tolerationSeconds":300}]}

COMMAND
  }

  depends_on = [
    null_resource.deploy_tekton
  ]
}

resource "null_resource" "crds" {
  triggers = {
    task        = md5(file("${path.module}/task.yaml"))
    pipeline    = md5(file("${path.module}/pipeline.yaml"))
    pipelinerun = md5(file("${path.module}/pipelinerun.yaml"))
    webhook     = md5(file("${path.module}/webhook.yaml"))
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<COMMAND
    set -x
    kubectl --server ${local.gkeClusterEndpoint} \
     --token ${local.gkeBearerToken}  \
     --insecure-skip-tls-verify=true  \
     apply -f ${path.module}/task.yaml \
    --namespace=${local.tektonNs}
    kubectl --server ${local.gkeClusterEndpoint} \
     --token ${local.gkeBearerToken}  \
     --insecure-skip-tls-verify=true  \
     apply -f ${path.module}/pipeline.yaml \
    --namespace=${local.tektonNs}
    kubectl --server ${local.gkeClusterEndpoint} \
     --token ${local.gkeBearerToken}  \
     --insecure-skip-tls-verify=true  \
     apply -f ${path.module}/webhook.yaml \
    --namespace=${local.tektonNs}
    kubectl --server ${local.gkeClusterEndpoint} \
     --token ${local.gkeBearerToken}  \
     --insecure-skip-tls-verify=true  \
     apply -f ${path.module}/pipelinerun.yaml \
    --namespace=${local.tektonNs}

COMMAND
  }
  depends_on = [
    null_resource.deploy_tekton,
    null_resource.harbor_creds
  ]
}

