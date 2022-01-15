
resource "null_resource" "mongod_crd_deploy" {
  triggers = {
    # playbook_contents  = md5(file("${path.module}/certificates.yaml.tmpl"))
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<COMMAND
    kubectl apply --server ${var.GkeClusterConnectionSettings.HOST}  \
     --token ${var.GkeClusterConnectionSettings.API_KEY}  --insecure-skip-tls-verify=true \
     -n mongo-system \
     -f https://raw.githubusercontent.com/percona/percona-server-mongodb-operator/master/deploy/crd.yaml
COMMAND
  }
}

resource "helm_release" "psmdb_operator" {
  name       = "psmdb-operator"
  namespace = var.MongoNs
  chart      = "psmdb-operator"
  repository = "https://percona.github.io/percona-helm-charts/"
  wait       = true
  atomic     = true
  timeout    = 900
  depends_on = [null_resource.mongod_crd_deploy]
}

data "vault_generic_secret" "mongo_creds" {
  path = var.CredsPath
}


resource "kubernetes_secret" "mongo" {
  metadata {
    name      = "mongo"
    namespace = var.MongoNs
  }

  data = data.vault_generic_secret.mongo_creds.data

}

data "vault_generic_secret" "minio_backup_user" {
  path = "secret/minio/root"
}

resource "kubernetes_secret" "mongo_backup" {
  metadata {
    name      = "mongo-backup"
    namespace = var.MongoNs
  }

  data = {
    AWS_ACCESS_KEY_ID     = data.vault_generic_secret.minio_backup_user.data.accessKey
    AWS_SECRET_ACCESS_KEY = data.vault_generic_secret.minio_backup_user.data.secretKey
  }

}

resource "helm_release" "mongo_cluster" {
  name      = "mongo-cluster"
  chart     = "${path.module}/mongo"
  namespace = var.MongoNs
  wait      = true
  atomic    = true
  set {
    name  = "BackupBucket"
    value = var.BackupBucket
  }
  set {
    name = "volumeSize"
    value = var.VolumeSize
  }
  set {
    name = "replicas"
    value = var.Replicas
  }
  set {
    name = "color"
    value = var.Color
  }
  set {
    name = "cpuReuest"
    value = local.request.cpu
  }
  set {
    name = "memReuest"
    value = local.request.memory
  }
  set {
    name = "memLimit"
    value = local.limit.memory
  }
  set {
    name = "cpuLimit"
    value = local.limit.cpu
  }
  depends_on = [
    helm_release.psmdb_operator,
    kubernetes_secret.mongo,
    kubernetes_secret.mongo_backup
  ]
}

resource "null_resource" "ansible_wait_for_mongo" {

  triggers = {
    playbook_contents = md5(file("${path.module}/../../ansible/k8s-wait-for.yml"))
    mongo          = helm_release.mongo_cluster.id
    operator = helm_release.psmdb_operator.id
  }
  provisioner "local-exec" {
    command = <<COMMAND
    cd ${path.module}/../../ansible &&\
    ansible-playbook k8s-wait-for.yml

COMMAND
    environment = merge(local.ansibleEnvs, {
      name           = "${var.Color}"
      kind           = "PerconaServerMongoDB"
      namespace      = var.MongoNs
      apiVersion     = "psmdb.percona.com/v1-4-0"
      statusPath     = "state"
      requiredStatus = "ready"
    })
  }
  depends_on = [
    helm_release.mongo_cluster
  ]
}

resource "helm_release" "mongo_express" {
  name      = "mongo-express"
  chart     = "${path.module}/mongo-express"
  namespace = var.MongoNs
  wait      = true
  atomic    = true
  set {
    name = "color"
    value = var.Color
  }
  depends_on = [
    null_resource.ansible_wait_for_mongo
  ]
}
