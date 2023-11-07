data "vault_generic_secret" "k8s_auth_inactive" {
  path = local.inactiveClusterVaultPath
}

data "vault_generic_secret" "k8s_auth_active" {
  path = local.activeClusterVaultPath
}

locals {
  command = <<COMMAND
    set -x

    echo "Stopping Kafka deployment"
    kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
    --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
    --insecure-skip-tls-verify=true  \
    get deploy -n kafka | grep -e kafka-cluster-entity-operator -e strimzi-cluster-operator | awk '{print $1}'\
    | xargs -n 1 -I{} \
    kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
    --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
    --insecure-skip-tls-verify=true  \
    scale deploy -n kafka --replicas=0 {}
    sleep 29


    echo "Deleting Kafka pods"
    kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
    --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
    --insecure-skip-tls-verify=true  \
    get pod -n kafka | grep -e kafka-cluster- | awk '{print $1}'\
    | xargs -n 1 -I{} \
    kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
    --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
    --insecure-skip-tls-verify=true  \
    delete pod -n kafka  {}
    sleep 29


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


    echo "Deleting Kafka PVCs"
    kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
    --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
    --insecure-skip-tls-verify=true  \
    get pvc -n kafka | grep -e kafka-cluster- | awk '{print $1}'\
    | xargs -n 1 -I{} \
    kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
    --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
    --insecure-skip-tls-verify=true  \
    delete pvc -n kafka  {}
    sleep 29


    echo "Stopping mongo operator"
    kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
    --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
    --insecure-skip-tls-verify=true  \
    get deploy -n mongo | grep -e psmdb-operator | awk '{print $1}'\
    | xargs -n 1 -I{} \
    kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
    --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
    --insecure-skip-tls-verify=true  \
    scale deploy -n mongo --replicas=0 {}
    sleep 29

    echo "Stopping mongo replicas"
    kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
    --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
    --insecure-skip-tls-verify=true  \
    scale statefulset -n mongo --replicas=0 --all


    echo "Deleting mongo PVCs"
    kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
    --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
    --insecure-skip-tls-verify=true  \
    get pvc -n mongo | grep -e data-mongo- | awk '{print $1}'\
    | xargs -n 1 -I{} \
    kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
    --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
    --insecure-skip-tls-verify=true  \
    delete pvc -n mongo  {}
    sleep 29


    echo "Stopping mongo-auth operator"
    kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
    --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
    --insecure-skip-tls-verify=true  \
    get deploy -n mongo-auth | grep -e psmdb-operator | awk '{print $1}'\
    | xargs -n 1 -I{} \
    kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
    --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
    --insecure-skip-tls-verify=true  \
    scale deploy -n mongo-auth --replicas=0 {}
    sleep 29


    echo "Stopping mongo-auth replicas"
    kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
    --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
    --insecure-skip-tls-verify=true  \
    scale statefulset -n mongo-auth --replicas=0 --all
    sleep 29


    echo "Deleting mongo-auth PVCs"
    kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
    --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
    --insecure-skip-tls-verify=true  \
    get pvc -n mongo-auth | grep -e data-mongo- | awk '{print $1}'\
    | xargs -n 1 -I{} \
    kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
    --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
    --insecure-skip-tls-verify=true  \
    delete pvc -n mongo-auth  {}

COMMAND
}


resource "null_resource" "stop_services" {

  triggers = {
    command = md5(local.command)
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = local.command
  }
}
