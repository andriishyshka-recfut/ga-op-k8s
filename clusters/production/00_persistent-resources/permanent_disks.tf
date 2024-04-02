locals {
  settings = jsondecode(file("${path.module}/../../../prod.tfvars.json")).Settings.clusters["production"]
  settings_red = jsondecode(file("${path.module}/../../../prod-red.tfvars.json")).Settings.clusters["production"]

  zones = local.settings.persistent_resources.permanentDisks.zones

  mongo_count       = local.settings.mongo.main.replicas
  mongo_prefix      = local.settings.mongo.main.pvcPrefix
  mongo_auth_count  = local.settings.mongo.auth.replicas
  mongo_auth_prefix = local.settings.mongo.auth.pvcPrefix

  kafka_count     = local.settings.persistent_resources.permanentDisks.kafka.count
  sonarqube_count = local.settings.persistent_resources.permanentDisks.sonarqube.count
  # sftp            = local.settings_red.sftp-server
  minio_count     = local.settings.persistent_resources.permanentDisks.minio.count

  tarantool_storage_count = local.settings_red.persistent_resources.permanentDisks.tarantool.storage_disks * 2
  tsc = local.settings_red.persistent_resources.permanentDisks.tarantool.storage_disks 
  tarantool_storage_prefix = local.settings_red.persistent_resources.permanentDisks.tarantool.storage_prefix 
  tarantool_router_count = local.settings_red.persistent_resources.permanentDisks.tarantool.router_disks
  tarantool_router_prefix = local.settings_red.persistent_resources.permanentDisks.tarantool.router_prefix 
  tarantool_etcd_count = local.settings_red.persistent_resources.permanentDisks.tarantool.etcd_disks
  tarantool_etcd_prefix = local.settings_red.persistent_resources.permanentDisks.tarantool.etcd_prefix 


  # mongoDiskSize = trim(local.settings.mongo.magescanner.volumeSize, "Gi")
  # mongoAuthDiskSize = trim(local.settings.mongo.magescanner.volumeSize, "Gi")
  restoreDate = local.settings.persistent_resources.permanentDisks.coldBackupDate

}


########
#   Set "restoreDate" (yyyy-mm-dd) to recover data as of that day
########


data "google_compute_snapshot" "mongo_snapshot" {
  name        = "${local.mongo_prefix}-${count.index}-dr-${local.restoreDate}"
  most_recent = true
  count       = local.mongo_count
}

data "google_compute_snapshot" "mongo_auth_snapshot" {
  name        = "${local.mongo_auth_prefix}-${count.index}-dr-${local.restoreDate}"
  most_recent = true
  count       = local.mongo_auth_count
}

data "google_compute_snapshot" "kafka_snapshot" {
  name        = "kafka-data-${count.index}-dr-${local.restoreDate}"
  most_recent = true
  count       = local.kafka_count
}

data "google_compute_snapshot" "kafka_zookeeper_snapshot" {
  name        = "kafka-zookeeper-${count.index}-dr-${local.restoreDate}"
  most_recent = true
  count       = local.kafka_count
}


data "google_compute_snapshot" "tarantool_storage_snapshot" {
  name        = "tarantool-storage-${element(range(local.tsc), floor(count.index / 2))}-${count.index % 2}-dr-${local.restoreDate}"
  most_recent = true
  count       = local.tarantool_storage_count
}


data "google_compute_snapshot" "tarantool_router_snapshot" {

  name        = "tarantool-router-${count.index}-0-dr-${local.restoreDate}"
  most_recent = true
  count       = local.tarantool_router_count
}

data "google_compute_snapshot" "sonarqube_postgres_snapshot" {
  name        = "sonarqube-postgres-${count.index}-adhoc"
  most_recent = true
  count       = local.sonarqube_count
}

# data "google_compute_snapshot" "sftp_snapshot" {
#   for_each    = local.sftp
#   name        = "${each.key}-config-dr-${local.restoreDate}"
#   most_recent = true
# }

data "google_compute_snapshot" "minio_tenant_snapshot" {
  name        = "minio-tenant-${count.index}-dr-${local.restoreDate}"
  most_recent = true
  count = local.minio_count
}

data "google_compute_snapshot" "tarantool_etcd_snapshot" {
  name        = "etcd-snapshot-${count.index}"
  most_recent = true
  count       = local.tarantool_etcd_count
}



resource "google_compute_disk" "mongo_pv" {
  name     = "${local.mongo_prefix}-${count.index}"
  count    = local.mongo_count
  type     = "pd-balanced"
  size     = data.google_compute_snapshot.mongo_snapshot[count.index].disk_size_gb
  snapshot = data.google_compute_snapshot.mongo_snapshot[count.index].name
  labels = {
    target = local.mongo_prefix
    id     = "${local.mongo_prefix}-${count.index}"
  }

  zone = element([for i in range(local.minio_count) : element(local.zones, i % 3)], count.index)
}

resource "google_compute_disk" "mongo_auth_pv" {
  name     = "${local.mongo_auth_prefix}-${count.index}"
  count    = local.mongo_count
  type     = "pd-balanced"
  size     = data.google_compute_snapshot.mongo_auth_snapshot[count.index].disk_size_gb
  snapshot = data.google_compute_snapshot.mongo_auth_snapshot[count.index].name
  labels = {
    target = local.mongo_auth_prefix
    id     = "${local.mongo_auth_prefix}-${count.index}"
  }

  zone = element([for i in range(local.minio_count) : element(local.zones, i % 3)], count.index)
}

resource "google_compute_disk" "kafka_pv" {
  name     = "kafka-data-${count.index}"
  count    = local.kafka_count
  type     = "pd-balanced"
  size     = data.google_compute_snapshot.kafka_snapshot[count.index].disk_size_gb
  snapshot = data.google_compute_snapshot.kafka_snapshot[count.index].name
  labels = {
    target = "kafka-data"
    id     = "kafka-data-${count.index}"
  }
  zone = element([for i in range(local.kafka_count) : element(local.zones, i % 3)], count.index)
}

resource "google_compute_disk" "kafka_zookeeper_pv" {
  name     = "kafka-zookeeper-${count.index}"
  count    = local.kafka_count
  type     = "pd-balanced"
  size     = data.google_compute_snapshot.kafka_zookeeper_snapshot[count.index].disk_size_gb
  snapshot = data.google_compute_snapshot.kafka_zookeeper_snapshot[count.index].name
  labels = {
    target = "kafka-zookeeper"
    id     = "kafka-zookeeper-${count.index}"
  }
  zone = element([for i in range(local.kafka_count) : element(local.zones, i % 3)], count.index)
}


resource "google_compute_disk" "tarantool_storage_pv" {
  name     = "tarantool-vortex-storage-${element(range(local.tsc), floor(count.index / 2))}-${count.index % 2}"
  count    = local.tarantool_storage_count
  type     = "pd-ssd"
  size     = data.google_compute_snapshot.tarantool_storage_snapshot[count.index].disk_size_gb
  snapshot = data.google_compute_snapshot.tarantool_storage_snapshot[count.index].name
  labels = {
    target = local.tarantool_storage_prefix
    id     = "${local.tarantool_storage_prefix}-${element(range(local.tsc), floor(count.index / 2))}-${count.index % 2}"
  }
  zone = element([for i in range(local.tarantool_storage_count) : element(local.zones, i % 3)], count.index)
}


resource "google_compute_disk" "tarantool_router_pv" {
  name     = "tarantool-vortex-router-${count.index}-0"
  count    = local.tarantool_router_count
  type     = "pd-ssd"
  size     = data.google_compute_snapshot.tarantool_router_snapshot[count.index].disk_size_gb
  snapshot = data.google_compute_snapshot.tarantool_router_snapshot[count.index].name
  labels = {
    target = local.tarantool_router_prefix
    id     = "${local.tarantool_router_prefix}-${count.index}"
  }
  zone = element([for i in range(local.tarantool_router_count) : element(local.zones, i % 3)], count.index)
}

resource "google_compute_disk" "sonarqube_postgres_pv" {
  name  = "sonarqube-postgres-${count.index}"
  count = local.sonarqube_count
  type  = "pd-balanced"
  # size     = 20
  size     = data.google_compute_snapshot.sonarqube_postgres_snapshot[count.index].disk_size_gb
  snapshot = data.google_compute_snapshot.sonarqube_postgres_snapshot[count.index].name
  labels = {
    target = "sonarqube-postgres"
    id     = "sonarqube-postgres-${count.index}"
  }

  zone = element([for i in range(local.minio_count) : element(local.zones, i % 3)], count.index)
}

# resource "google_compute_disk" "sftp_pv" {
#   for_each = local.sftp
#   name     = "sftp-server-${each.key}-config"
#   type     = "pd-balanced"
#   size     = data.google_compute_snapshot.sftp_snapshot[each.key].disk_size_gb
#   snapshot = data.google_compute_snapshot.sftp_snapshot[each.key].name
#   labels = {
#     target = "sftp-server-${each.key}-config"
#     id     = "sftp-server-${each.key}-config"
#   }

#   zone = each.value.zone
# }



resource "google_compute_disk" "minio_pv" {
  count = local.minio_count

  name     = "minio-pv-${count.index}"
  size     = data.google_compute_snapshot.minio_tenant_snapshot[count.index].disk_size_gb
  snapshot = data.google_compute_snapshot.minio_tenant_snapshot[count.index].name
  type     = "pd-balanced"

  zone = element([for i in range(local.minio_count) : element(local.zones, i % 3)], count.index)

  labels = {
    target = "minio-tenant"
  }
}

resource "google_compute_disk" "tarantool_etcd_pv" {
  name     = "${local.tarantool_etcd_prefix}-${count.index}"
  count    = local.tarantool_etcd_count
  type     = "pd-ssd"
  size     = data.google_compute_snapshot.tarantool_etcd_snapshot[count.index].disk_size_gb
  snapshot = data.google_compute_snapshot.tarantool_etcd_snapshot[count.index].name
  labels = {
    target = local.tarantool_etcd_prefix
    id     = "${local.tarantool_etcd_prefix}-${count.index}"
  }
  zone = element([for i in range(local.tarantool_etcd_count) : element(local.zones, i % 3)], count.index)
}