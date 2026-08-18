data "vault_generic_secret" "k8s_auth_inactive" {
  path = local.inactiveClusterVaultPath
}

data "vault_generic_secret" "k8s_auth_active" {
  path = local.activeClusterVaultPath
}

locals {
  cluster_settings = var.Settings.clusters[var.Cluster]

  postgres_ha_profiles = try(local.cluster_settings["postgresql-ha"], {})
  enabled_postgres_ha_profiles = {
    for name, cfg in local.postgres_ha_profiles : name => cfg
    if lookup(cfg, "enabled", false)
  }
  postgres_ha_targets = [
    for profile_name in sort(keys(local.enabled_postgres_ha_profiles)) : {
      profile_name = profile_name
      namespace    = try(local.enabled_postgres_ha_profiles[profile_name].namespace, "postgres")
      cluster_name = try(local.enabled_postgres_ha_profiles[profile_name].cluster_name, "postgresql-ha")
      pvc_prefix   = "data-${try(local.enabled_postgres_ha_profiles[profile_name].cluster_name, "postgresql-ha")}-postgresql"
    }
  ]

  stop_kafka = <<COMMAND
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
COMMAND


  delete_kafka_resources = <<COMMAND
    set -x

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
COMMAND


  stop_mongo = <<COMMAND
    set -x

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
COMMAND

  stop_mongo_auth = <<COMMAND
    set -x

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
COMMAND


  stop_minio_helm = <<COMMAND
    set -x

    echo "Stopping minio-helm replicas"
    kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
    --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
    --insecure-skip-tls-verify=true  \
    scale statefulset -n minio-helm --replicas=0 --all
COMMAND


  delete_mongo_resources = <<COMMAND
    set -x

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
COMMAND


  delete_mongo_auth_resources = <<COMMAND
    set -x

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

  delete_minio_helm_resources = <<COMMAND
    set -x

    echo "Deleting minio-helm PVCs"
    kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
    --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
    --insecure-skip-tls-verify=true  \
    get pvc -n minio-helm | grep -e data0-minio- | awk '{print $1}'\
    | xargs -n 1 -I{} \
    kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
    --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
    --insecure-skip-tls-verify=true  \
    delete pvc -n minio-helm {}
COMMAND

  stop_postgres_resources = <<COMMAND
    set -x

    echo "Stop postgres operator"
    kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
    --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
    --insecure-skip-tls-verify=true  \
    scale deployment -n postgres --replicas=0 cnpg-cloudnative-pg
    sleep 29

    echo "Deleting postgres pods"
    kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
    --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
    --insecure-skip-tls-verify=true  \
    get pod -n postgres | grep -e postgres- | awk '{print $1}'\
    | xargs -n 1 -I{} \
    kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
    --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
    --insecure-skip-tls-verify=true  \
    delete pod -n postgres  {}
    sleep 29

    echo "Deleting postgres PVCs"
    kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
    --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
    --insecure-skip-tls-verify=true  \
    get pvc -n postgres | grep -e postgres- | awk '{print $1}'\
    | xargs -n 1 -I{} \
    kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
    --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
    --insecure-skip-tls-verify=true  \
    delete pvc -n postgres  {}
COMMAND

  stop_postgres_ha_resources = <<COMMAND
    set -x

${join("\n\n", [
  for target in local.postgres_ha_targets : <<-EOT
    echo "Stopping postgres-ha profile ${target.profile_name}"

    echo "Stopping postgres-ha statefulsets"
    kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
    --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
    --insecure-skip-tls-verify=true  \
    get statefulset -n ${target.namespace} -l app.kubernetes.io/instance=${target.cluster_name} -o name \
    | xargs -r -n 1 -I{} \
    kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
    --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
    --insecure-skip-tls-verify=true  \
    scale -n ${target.namespace} --replicas=0 {}

    echo "Stopping postgres-ha deployments"
    kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
    --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
    --insecure-skip-tls-verify=true  \
    get deployment -n ${target.namespace} -l app.kubernetes.io/instance=${target.cluster_name} -o name \
    | xargs -r -n 1 -I{} \
    kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
    --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
    --insecure-skip-tls-verify=true  \
    scale -n ${target.namespace} --replicas=0 {}
    sleep 29

    echo "Deleting postgres-ha pods"
    kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
    --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
    --insecure-skip-tls-verify=true  \
    get pod -n ${target.namespace} -l app.kubernetes.io/instance=${target.cluster_name} -o name \
    | xargs -r -n 1 -I{} \
    kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
    --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
    --insecure-skip-tls-verify=true  \
    delete -n ${target.namespace} {}
    sleep 29

    echo "Deleting postgres-ha PVCs"
    kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
    --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
    --insecure-skip-tls-verify=true  \
    get pvc -n ${target.namespace} | grep -e ${target.pvc_prefix}- | awk '{print $1}' \
    | xargs -r -n 1 -I{} \
    kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
    --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
    --insecure-skip-tls-verify=true  \
    delete pvc -n ${target.namespace} {}
EOT
])}
COMMAND

stop_elastic_resources = <<COMMAND
    set -x

    echo "Stopping elastic replicas"
    kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
    --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
    --insecure-skip-tls-verify=true  \
    scale statefulset -n elastic --replicas=0 --all

    echo "Deleting elastic PVCs"
    kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
    --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
    --insecure-skip-tls-verify=true  \
    get pvc -n elastic | awk '{print $1}'\
    | xargs -n 1 -I{} \
    kubectl --server ${data.vault_generic_secret.k8s_auth_inactive.data.HOST}  \
    --token ${data.vault_generic_secret.k8s_auth_inactive.data.k8s_sa_token}  \
    --insecure-skip-tls-verify=true  \
    delete pvc -n elastic  {}
  
COMMAND

}



resource "null_resource" "stop_kafka" {

  triggers = {
    command = md5(local.stop_kafka)
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = local.stop_kafka
  }
}

resource "null_resource" "delete_kafka_resources" {

  triggers = {
    command = md5(local.delete_kafka_resources)
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = local.delete_kafka_resources
  }
  depends_on = [null_resource.stop_kafka]
}

resource "null_resource" "stop_mongo" {

  triggers = {
    command = md5(local.stop_mongo)
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = local.stop_mongo
  }
}

resource "null_resource" "stop_mongo_auth" {

  triggers = {
    command = md5(local.stop_mongo_auth)
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = local.stop_mongo_auth
  }
}

resource "null_resource" "stop_minio_helm" {

  triggers = {
    command = md5(local.stop_mongo_auth)
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = local.stop_minio_helm
  }
}

resource "null_resource" "delete_mongo_resources" {

  triggers = {
    command = md5(local.delete_mongo_resources)
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = local.delete_mongo_resources
  }
  depends_on = [null_resource.stop_mongo]
}


resource "null_resource" "delete_mongo_auth_resources" {

  triggers = {
    command = md5(local.delete_mongo_auth_resources)
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = local.delete_mongo_auth_resources
  }
  depends_on = [null_resource.stop_mongo_auth]
}

resource "null_resource" "delete_minio_helm_resources" {

  triggers = {
    command = md5(local.delete_minio_helm_resources)
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = local.delete_minio_helm_resources
  }
  depends_on = [null_resource.stop_minio_helm]
}

resource "null_resource" "stop_postgres_resources" {

  triggers = {
    command = md5(local.stop_postgres_resources)
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = local.stop_postgres_resources
  }
}

resource "null_resource" "stop_postgres_ha_resources" {
  count = length(local.postgres_ha_targets) > 0 ? 1 : 0

  triggers = {
    command = md5(local.stop_postgres_ha_resources)
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = local.stop_postgres_ha_resources
  }
}

resource "null_resource" "stop_elastic_resources" {
  count = var.Cluster == "sandbox" ? 1 : 0
  triggers = {
    command = md5(local.stop_elastic_resources)
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = local.stop_elastic_resources
  }
}
