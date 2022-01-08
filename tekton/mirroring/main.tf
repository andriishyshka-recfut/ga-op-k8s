data "vault_generic_secret" "k8s_auth_inactive" {
  path = local.inactiveClusterVaultPath
}


data "external" "get_remote_node" {
  program = ["bash", "${path.module}/get-node-ip.sh"]
  query = {
    server = data.vault_generic_secret.k8s_auth_inactive.data.HOST
    token = data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token
  }
}

locals {
  yaml = replace(
                  file("${path.module}/MM2.yaml"),
                  "CHANGEME",
                  data.external.get_remote_node.result.ip
                  )
}


resource "null_resource" "chek_kafka_connect" {

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<COMMAND
    set -x
    kubectl --server ${data.vault_generic_secret.k8s_auth.data.HOST}  \
     --token ${data.vault_generic_secret.k8s_auth.data.k8s_sa_token}  \
     --insecure-skip-tls-verify=true  \
     exec  -it -n kafka kafka-cluster-kafka-2 -c kafka -- bin/kafka-topics.sh --bootstrap-server ${data.external.get_remote_node.result.ip}:32100 --list
COMMAND
  }
}


resource "kubectl_manifest" "mm2" {
  yaml_body  = local.yaml
  depends_on = [
    null_resource.chek_kafka_connect
  ]
}
