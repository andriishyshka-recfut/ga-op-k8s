data "vault_generic_secret" "k8s_auth_inactive" {
  path = local.inactiveClusterVaultPath
}

data "vault_generic_secret" "k8s_auth_active" {
  path = local.activeClusterVaultPath
}

locals {
  create_kafka_crd = <<COMMAND
    set -x

    echo "Creating Kafka CRD"
    kubectl  --server ${data.vault_generic_secret.k8s_auth_active.data.HOST}  \
    --token ${data.vault_generic_secret.k8s_auth_active.data.k8s_sa_token}  \
    --insecure-skip-tls-verify=true create -f ${path.module}/kafka-topic.yaml
    sleep 10
COMMAND


  clone_topics = <<COMMAND
    set -x

    echo "Transfering Kafka topics to new cluster"
    kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
    --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
    --insecure-skip-tls-verify=true  \
    get kafkatopic -n kafka | grep -v -e NAME | awk '{print $1}'\
    | xargs -n 1 -I{} \
    sh -c "kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
    --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
    --insecure-skip-tls-verify=true  \
    get kafkatopic -n kafka {} -o yaml | kubectl  --server ${data.vault_generic_secret.k8s_auth_active.data.HOST}  \
    --token ${data.vault_generic_secret.k8s_auth_active.data.k8s_sa_token}  \
    --insecure-skip-tls-verify=true apply -f -"
    sleep 29
COMMAND

}


resource "null_resource" "create_kafka_crd" {

  triggers = {
    command = md5(local.create_kafka_crd)
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = local.create_kafka_crd
  }
}

resource "null_resource" "clone_topics" {

  triggers = {
    command = md5(local.clone_topics)
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = local.clone_topics
  }
  depends_on = [ null_resource.create_kafka_crd ]
}