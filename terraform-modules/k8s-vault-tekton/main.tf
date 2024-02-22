resource "null_resource" "deploy_tekton" {

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<COMMAND
    set -x
    kubectl --server ${local.gkeClusterEndpoint} \
     --token ${local.gkeBearerToken} \
     --insecure-skip-tls-verify=true \
     create namespace ${local.tektonNs} && \
    kubectl apply --server ${local.gkeClusterEndpoint} \
     --token ${local.gkeBearerToken} \
     --insecure-skip-tls-verify=true \
     -f https://storage.googleapis.com/tekton-releases/operator/latest/release.yaml && sleep 30 && \
    kubectl --server ${local.gkeClusterEndpoint} \
     --token ${local.gkeBearerToken} \
     --insecure-skip-tls-verify=true \
     --namespace=${local.tektonNs} \
     create configmap cluster-settings --from-literal=cluster=${var.Cluster} --from-literal=color=${var.Color} --from-literal=configPath=${local.configPath} \
     --from-literal=vaultAddr=${var.VaultAddress} && \
    kubectl --server ${local.gkeClusterEndpoint} \
     --token ${local.gkeBearerToken} \
     --insecure-skip-tls-verify=true  \
     --namespace=${local.tektonMainNs} \
     create configmap cluster-settings --from-literal=cluster=${var.Cluster} --from-literal=color=${var.Color} --from-literal=configPath=${local.configPath} \
     --from-literal=vaultAddr=${var.VaultAddress} && \
    kubectl --server ${local.gkeClusterEndpoint}  \
     --token ${local.gkeBearerToken} \
     --insecure-skip-tls-verify=true  \
     --namespace=${local.tektonMainNs} \
     patch configmap config-defaults --type json \
     --patch '[{"op": "add", "path":"/data/default-pod-template","value": "imagePullSecrets:\n  - name: harbor\naffinity:\n  nodeAffinity:\n    requiredDuringSchedulingIgnoredDuringExecution:\n      nodeSelectorTerms:\n        - matchExpressions:\n            - key: workloadsType\n              operator: In\n              values:\n                - tekton\ntolerations:\n  - key: \"workloadsType\"\n    operator: \"Equal\"\n    value: \"tekton\"\n    effect: \"NoSchedule\"\n  - key: node.kubernetes.io/not-ready\n    operator: Exists\n    effect: NoExecute\n    tolerationSeconds: 300\n  - key: node.kubernetes.io/unreachable\n    operator: Exists\n    effect: NoExecute\n    tolerationSeconds: 300"}]'
COMMAND
  }

}

resource "null_resource" "harbor_creds" {

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<COMMAND
    set -x
    export VAULT_ADDR=${var.VaultAddress}
    kubectl patch --server ${local.gkeClusterEndpoint}  \
     --token ${local.gkeBearerToken}  \
     --insecure-skip-tls-verify=true  \
     --namespace=${local.tektonNs}  \
     serviceaccount default -p '{"imagePullSecrets": [{"name": "harbor"}]}' && sleep 30 && \
    kubectl patch --server ${local.gkeClusterEndpoint}  \
     --token ${local.gkeBearerToken}  \
     --insecure-skip-tls-verify=true  \
     --namespace=${local.tektonMainNs}  \
     serviceaccount default -p '{"imagePullSecrets": [{"name": "harbor"}]}'
COMMAND
  }

  depends_on = [
    null_resource.deploy_tekton
  ]
}

data "vault_generic_secret" "goharbor" {
  path = "secret/goharbor/docker_login"
}

resource "kubernetes_secret" "harbor_creds" {
  metadata {
    name = "harbor"
    namespace = local.tektonMainNs
  }

  type = "kubernetes.io/dockerconfigjson"
  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "${local.registry_server}" = {
          "username" = data.vault_generic_secret.goharbor.data.user
          "password" = data.vault_generic_secret.goharbor.data.password
          "auth"     = base64encode("${data.vault_generic_secret.goharbor.data.user}:${data.vault_generic_secret.goharbor.data.password}")
        }
      }
    })
  }
}

resource "kubernetes_secret" "harbor_creds" {
  metadata {
    name = "harbor"
    namespace = local.tektonNs
  }

  type = "kubernetes.io/dockerconfigjson"
  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "${local.registry_server}" = {
          "username" = data.vault_generic_secret.goharbor.data.user
          "password" = data.vault_generic_secret.goharbor.data.password
          "auth"     = base64encode("${data.vault_generic_secret.goharbor.data.user}:${data.vault_generic_secret.goharbor.data.password}")
        }
      }
    })
  }
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
     apply -f ${path.module}/task.yaml
    kubectl --server ${local.gkeClusterEndpoint} \
     --token ${local.gkeBearerToken}  \
     --insecure-skip-tls-verify=true  \
     apply -f ${path.module}/pipeline.yaml
    kubectl --server ${local.gkeClusterEndpoint} \
     --token ${local.gkeBearerToken}  \
     --insecure-skip-tls-verify=true  \
     apply -f ${path.module}/webhook.yaml
    kubectl --server ${local.gkeClusterEndpoint} \
     --token ${local.gkeBearerToken}  \
     --insecure-skip-tls-verify=true  \
     apply -f ${path.module}/pipelinerun.yaml

COMMAND
  }
  depends_on = [
    null_resource.deploy_tekton,
    null_resource.harbor_creds
  ]
}

# ### For Bots-mongo-restart
#  data "vault_generic_secret" "mongo_creds" {
#    path = local.mongoCredsPath
#  }

#  resource "kubernetes_secret" "mongo_auth" {
#    metadata {
#      name      = "mongo-auth"
#      namespace = local.tektonMainNs
#    }
#    data = {
#      MONGODB_BACKUP_USER     = data.vault_generic_secret.mongo_creds.data.MONGODB_BACKUP_USER
#      MONGODB_BACKUP_PASSWORD = data.vault_generic_secret.mongo_creds.data.MONGODB_BACKUP_PASSWORD
#      URI                     = data.vault_generic_secret.mongo_creds.data.URI
#    }
#  }

