data "vault_generic_secret" "mongo_creds" {
  path = var.CredsPath
}

data "vault_generic_secret" "minio_backup_user" {
  path = "secret/minio/root"
}

data "vault_generic_secret" "mongo_encryption_key" {
  path = "secret/mongo/encryption-mongo6-${var.InstanceName}"
}




resource "helm_release" "psmdb_operator" {
  name       = "psmdb-operator"
  namespace  = var.MongoNs
  version    = "1.15.0"
  chart      = "psmdb-operator"
  repository = "https://percona.github.io/percona-helm-charts/"
  wait       = true
  atomic     = true
  timeout    = 900
  # depends_on = [null_resource.mongod_crd_deploy]
  depends_on = [ kubernetes_secret.mongo_encryption_key ]
}


resource "kubernetes_secret" "mongo_users" {
  metadata {
    name      = local.full_name
    namespace = var.MongoNs
  }
  data = data.vault_generic_secret.mongo_creds.data
}


resource "kubernetes_secret" "mongo" {
  metadata {
    name      = "mongo"
    namespace = var.MongoNs
  }
  data = data.vault_generic_secret.mongo_creds.data
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



resource "kubernetes_secret" "mongo_encryption_key" {
  metadata {
    name      = "mongo-${var.InstanceName}-mongodb-encryption-key"
    namespace = var.MongoNs
  }
  data = {
    encryption-key = data.vault_generic_secret.mongo_encryption_key.data.key
  }
}




resource "helm_release" "mongo_cluster" {
  name       = "mongo-cluster"
  chart      = "psmdb-db"
  repository = "https://percona.github.io/percona-helm-charts/"
  version    = "1.15.3"
  namespace  = var.MongoNs
  wait       = true
  atomic     = true

  values = [
    "${file("${path.module}/values.yaml")}"
  ]

  set = [
    {
      name  = "fullnameOverride"
      value = local.full_name
    },
    {
      name  = "image.tag"
      value = var.ImageTag
    },
    {
      name  = "image.repository"
      value = var.Repository
    },
    {
      name  = "backup.storages.minio.s3.bucket"
      value = var.BackupBucket
    },
    {
      name  = "replsets[0].volumeSpec.pvc.resources.requests.storage"
      value = var.VolumeSize
    },
    {
      name  = "replsets[0].size"
      value = var.Replicas
    },
    {
      name  = "replsets[0].resources.requests.cpu"
      value = local.request.cpu
    },
    {
      name  = "replsets[0].resources.requests.memory"
      value = local.request.memory
    },
    {
      name  = "replsets[0].resources.limits.memory"
      value = local.limit.memory
    },
    {
      name  = "replsets[0].resources.limits.cpu"
      value = local.limit.cpu
    },
    {
      name  = "replsets[0].sidecars[0].image"
      value = local.exporterImage
    }
  ]
  depends_on = [
    helm_release.psmdb_operator,
    kubernetes_secret.mongo,
    kubernetes_secret.mongo_backup,
    kubernetes_persistent_volume.mongo_data_pv
  ]
}

# resource "null_resource" "ansible_wait_for_mongo" {

#   triggers = {
#     playbook_contents = md5(file("${path.module}/../../ansible/k8s-wait-for.yml"))
#     mongo             = helm_release.mongo_cluster.id
#     operator          = helm_release.psmdb_operator.id
#   }
#   provisioner "local-exec" {
#     command = <<COMMAND
#     cd ${path.module}/../../ansible &&\
#     ansible-playbook k8s-wait-for.yml

# COMMAND
#     environment = merge(local.ansibleEnvs, {
#       name           = local.full_name
#       kind           = "PerconaServerMongoDB"
#       namespace      = var.MongoNs
#       apiVersion     = "psmdb.percona.com/v1"
#       statusPath     = "state"
#       requiredStatus = "ready"
#     })
#   }
#   depends_on = [
#     helm_release.mongo_cluster
#   ]
# }

resource "helm_release" "mongo_express" {
  name      = "mongo-express"
  chart     = "${path.module}/mongo-express"
  namespace = var.MongoNs
  wait      = true
  atomic    = true
  set = [
    {
      name  = "fullName"
      value = local.full_name
    }
  ]
  # depends_on = [
  #   null_resource.ansible_wait_for_mongo
  # ]
}
