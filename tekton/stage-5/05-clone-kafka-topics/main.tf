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


  delete_topics = <<COMMAND
    set -x

    echo "Delete existing Kafka topics in new cluster"
    kubectl  --server ${data.vault_generic_secret.k8s_auth_active.data.HOST}  \
    --token ${data.vault_generic_secret.k8s_auth_active.data.k8s_sa_token}  \
    --insecure-skip-tls-verify=true delete KafkaTopic --all -n kafka
COMMAND

  clone_topics = <<COMMAND
    set -x

    echo "Delete existing Kafka topics in new cluster"
    kubectl  --server ${data.vault_generic_secret.k8s_auth_active.data.HOST}  \
    --token ${data.vault_generic_secret.k8s_auth_active.data.k8s_sa_token}  \
    --insecure-skip-tls-verify=true delete KafkaTopic --all -n kafka

    echo "Transfering Kafka topics to new cluster"
    kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
    --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
    --insecure-skip-tls-verify=true  \
    get kafkatopic -n kafka -o yaml |  kubectl  --server ${data.vault_generic_secret.k8s_auth_active.data.HOST}  \
    --token ${data.vault_generic_secret.k8s_auth_active.data.k8s_sa_token}  \
    --insecure-skip-tls-verify=true apply -f -
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


resource "null_resource" "delete_old_topics" {

  triggers = {
    command = md5(local.delete_topics)
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = local.delete_topics
  }
  depends_on = [ null_resource.create_kafka_crd ]
}


resource "null_resource" "clone_topics" {

  triggers = {
    command = md5(local.clone_topics)
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = local.clone_topics
  }
  depends_on = [ null_resource.delete_topics ]
}