resource "helm_release" "psmdb_operator" {
  name       = "psmdb-operator"
  namespace  = var.MongoNs
  version    = "1.13.0"
  chart      = "psmdb-operator"
  repository = "https://percona.github.io/percona-helm-charts/"
  wait       = true
  atomic     = true
  timeout    = 900
  # depends_on = [null_resource.mongod_crd_deploy]
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


data "vault_generic_secret" "mongo_encryption_key" {
  count = local.encryption_keys_count
  path = "secret/mongo/encryption-${var.InstanceName}"
}


resource "kubernetes_secret" "mongo_encryption_key" {
  count = local.encryption_keys_count
  metadata {
    name      = "mongo-${var.InstanceName}-mongodb-encryption-key"
    namespace = var.MongoNs
  }
  data = {
    encryption-key = data.vault_generic_secret.mongo_encryption_key[count.index].data.key
  }
}





resource "kubernetes_persistent_volume" "mongo_data_pv" {
  count = local.pv_disk_count
  metadata {
    name = "${local.target_label}-${count.index}-pv"
    labels = {
      target = local.target_label
    }
  }
  spec {
    capacity = {
      storage = var.VolumeSize
    }
    access_modes = ["ReadWriteOnce"]
    claim_ref {
      namespace = var.MongoNs
      name = "${local.claim_prefix}-rs0-${count.index}"
    }
    persistent_volume_source{
      csi {
        driver = "pd.csi.storage.gke.io"
        volume_handle = "projects/${var.Settings.gcpProject}/regions/${var.Settings.clusters[var.Cluster].region}/disks/${local.target_label}-${count.index}"
      }
    }
  node_affinity {
      required {
        node_selector_term {
          match_expressions {
            key = "topology.gke.io/zone"
            operator = "In"
            values = [ "us-east4-a", "us-east4-b"]            
          }
        }
      }
    }
  }
}

resource "helm_release" "mongo_cluster" {
  name      = "mongo-cluster"
  chart     = "${path.module}/mongo"
  namespace = var.MongoNs
  wait      = true
  atomic    = true

  values = [
    "${file("${path.module}/values.yaml")}"
  ]

  set {
    name = "fullnameOverride"
    value = local.full_name
  }
  set {
    name  = "image.tag"
    value = var.ImageTag
  }
  set {
    name  = "image.repository"
    value = var.Repository
  }
  set {
    name  = "backup.storages.minio.s3.bucket"
    value = var.BackupBucket
  }
  set {
    name  = "replsets[0].volumeSpec.pvc.resources.requests.storage"
    value = var.VolumeSize
  }
  
  #Clever hack with "IF". Remove before May's DR
  dynamic "set" {
    for_each = var.Cluster == "sandbox" ? [var.Cluster] : []
    content {
      name = "replset.volumeSpec.pvc"
      value = yamlencode(local.pvc_config)
    }
  }

  set {
    name  = "replicas"
    value = var.Replicas
  }
  set {
    name  = "color"
    value = var.Color
  }
  set {
    name  = "replsets[0].resources.requests.cpu"
    value = local.request.cpu
  }
  set {
    name  = "replsets[0].resources.requests.memory"
    value = local.request.memory
  }
  set {
    name  = "replsets[0].resources.limits.memory"
    value = local.limit.memory
  }
  set {
    name  = "replsets[0].resources.limits.cpu"
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
    mongo             = helm_release.mongo_cluster.id
    operator          = helm_release.psmdb_operator.id
  }
  provisioner "local-exec" {
    command = <<COMMAND
    cd ${path.module}/../../ansible &&\
    ansible-playbook k8s-wait-for.yml

COMMAND
    environment = merge(local.ansibleEnvs, {
      name           = local.full_name
      kind           = "PerconaServerMongoDB"
      namespace      = var.MongoNs
      apiVersion     = "psmdb.percona.com/v1"
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
    name  = "fullName"
    value = local.full_name
  }
  depends_on = [
    null_resource.ansible_wait_for_mongo
  ]
}
