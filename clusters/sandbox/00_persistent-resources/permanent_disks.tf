locals {
  settings = jsondecode(file("${path.module}/../../../config.tfvars.json")).Settings.clusters["sandbox"]

  zones = local.settings.persistent_resources.permanentDisks.zones

  mongo_count       = local.settings.mongo6.main.replicas
  mongo_prefix      = local.settings.mongo6.main.pvcPrefix
  mongo_auth_count  = local.settings.mongo6.auth.replicas
  mongo_auth_prefix = local.settings.mongo6.auth.pvcPrefix


  mongo6_count  = local.settings.mongo6.main.replicas
  mongo6_prefix = local.settings.mongo6.main.pvcPrefix

  kafka_count     = local.settings.persistent_resources.permanentDisks.kafka.count
  sonarqube_count = local.settings.persistent_resources.permanentDisks.sonarqube.count
  # sftp            = local.settings.sftp-server
  sftp           = {}
  minio_count    = local.settings.persistent_resources.permanentDisks.minio.count
  postgres_count = local.settings.persistent_resources.permanentDisks.postgres.count
  elastic_disks = { for new_name in flatten([ for nodepool in local.settings.persistent_resources.permanentDisks.elastic.elasticsearch : [for disk in range(nodepool.count) : { name = nodepool.name, size = nodepool.size, index = disk, count = nodepool.count} ]]): "${new_name.name}-${new_name.index}" => new_name } 
  elastic8_disks = { for new_name in flatten([ for nodepool in local.settings.persistent_resources.permanentDisks.elastic.elastic8 : [for disk in range(nodepool.count) : { name = nodepool.name, size = nodepool.size, index = disk, count = nodepool.count} ]]): "${new_name.name}-${new_name.index}" => new_name } 
  tarantool_storage_count  = local.settings.persistent_resources.permanentDisks.tarantool.storage_disks * 2
  tsc                      = local.settings.persistent_resources.permanentDisks.tarantool.storage_disks
  tarantool_storage_prefix = local.settings.persistent_resources.permanentDisks.tarantool.storage_prefix
  tarantool_router_count   = local.settings.persistent_resources.permanentDisks.tarantool.router_disks
  tarantool_router_prefix  = local.settings.persistent_resources.permanentDisks.tarantool.router_prefix
  tarantool_etcd_count     = local.settings.persistent_resources.permanentDisks.tarantool.etcd_disks
  tarantool_etcd_prefix    = local.settings.persistent_resources.permanentDisks.tarantool.etcd_prefix



  # mongoDiskSize = trim(local.settings.mongo6.main.volumeSize, "Gi")
  # mongoAuthDiskSize = trim(local.settings.mongo6.main.volumeSize, "Gi")
  restoreDate = local.settings.persistent_resources.permanentDisks.coldBackupDate

}


########
#   Set "restoreDate" (yyyy-mm-dd) to recover data as of that day
########

data "google_compute_snapshot" "elastic_snapshot" {
  for_each = local.elastic_disks
  name        = "elastic-${each.key}-${local.restoreDate}"
  most_recent = true
}
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

data "google_compute_snapshot" "kafka_controller_snapshot" {
  name        = "kafka-controller-${count.index}-dr-${local.restoreDate}"
  most_recent = true
  count       = local.kafka_count
}

data "google_compute_snapshot" "postgres_snapshot" {
  name        = "postgres-data-${count.index}-dr-${local.restoreDate}"
  most_recent = true
  count       = local.postgres_count
}

data "google_compute_snapshot" "tarantool_storage_snapshot" {
  name        = "tarantool-vortex-cartridge-storage-${element(range(local.tsc), floor(count.index / 2))}-${count.index % 2}-bcp-${local.restoreDate}"
  most_recent = true
  count       = local.tarantool_storage_count
}

data "google_compute_snapshot" "tarantool_router_snapshot" {
  name        = "tarantool-vortex-cartridge-router-${count.index}-0-bcp-${local.restoreDate}"
  most_recent = true
  count       = local.tarantool_router_count
}

data "google_compute_snapshot" "tarantool_etcd_snapshot" {
  name        = "tarantool-etcd-${count.index}-dr-${local.restoreDate}"
  most_recent = true
  count       = local.tarantool_etcd_count
}

data "google_compute_snapshot" "sonarqube_postgres_snapshot" {
  name        = "sonarqube-postgres-${count.index}-adhoc"
  most_recent = true
  count       = local.sonarqube_count
}

data "google_compute_snapshot" "sftp_snapshot" {
  for_each    = local.sftp
  name        = "${each.key}-config-dr-${local.restoreDate}"
  most_recent = true
}

data "google_compute_snapshot" "minio_tenant_snapshot" {
  name        = "minio-tenant-bcp2-${count.index}"
  most_recent = true
  count       = local.minio_count
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

  zone = element([for i in range(local.mongo_count) : element(local.zones, i % 3)], count.index)
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

  zone = element([for i in range(local.mongo_count) : element(local.zones, i % 3)], count.index)
}


resource "google_compute_disk" "mongo6_pv" {
  name     = "${local.mongo6_prefix}-${count.index}"
  count    = local.mongo_count
  type     = "pd-balanced"
  size     = data.google_compute_snapshot.mongo_snapshot[count.index].disk_size_gb
  snapshot = data.google_compute_snapshot.mongo_snapshot[count.index].name
  labels = {
    target = local.mongo6_prefix
    id     = "${local.mongo6_prefix}-${count.index}"
  }

  zone = element([for i in range(local.mongo_count) : element(local.zones, i % 3)], count.index)
}

resource "google_compute_disk" "elastic_pv" {
  for_each = local.elastic_disks
  name     = "elastic-${each.key}"
  type     = "pd-balanced"
  size     = each.value.size
  snapshot = data.google_compute_snapshot.elastic_snapshot[each.key].name
  labels = {
    target = "elastic-${each.value.name}"
    id     = "elastic-${each.key}"
  }
  zone = element([for i in range(each.value.count) : element(local.zones, i % 3)], each.value.index)
}
resource "google_compute_disk" "elastic8_pv" {
  for_each = local.elastic_disks
  name     = "elastic8-${each.key}"
  type     = "pd-balanced"
  size     = each.value.size
  labels = {
    target = "elastic8-${each.value.name}"
    id     = "elastic8-${each.key}"
  }
  zone = element([for i in range(each.value.count) : element(local.zones, i % 3)], each.value.index)
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
  zone = element([for i in range(local.minio_count) : element(local.zones, i % 3)], count.index)
}

resource "google_compute_disk" "kafka_controller_pv" {
  name     = "kafka-controller-${count.index}"
  count    = local.kafka_count
  type     = "pd-balanced"
  size     = data.google_compute_snapshot.kafka_controller_snapshot[count.index].disk_size_gb
  snapshot = data.google_compute_snapshot.kafka_controller_snapshot[count.index].name
  labels = {
    target = "kafka-controller"
    id     = "kafka-controller-${count.index}"
  }
  zone = element([for i in range(local.minio_count) : element(local.zones, i % 3)], count.index)
}

resource "google_compute_disk" "tarantool_storage_pv" {
  name     = "tarantool-vortex-storage-${element(range(local.tsc), floor(count.index / 2))}-${count.index % 2}"
  count    = local.tarantool_storage_count
  type     = "pd-balanced"
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
  type     = "pd-balanced"
  size     = data.google_compute_snapshot.tarantool_router_snapshot[count.index].disk_size_gb
  snapshot = data.google_compute_snapshot.tarantool_router_snapshot[count.index].name
  labels = {
    target = local.tarantool_router_prefix
    id     = "${local.tarantool_router_prefix}-${count.index}"
  }
  zone = element([for i in range(local.tarantool_router_count) : element(local.zones, i % 3)], count.index)
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

resource "google_compute_disk" "sftp_pv" {
  for_each = local.sftp
  name     = "sftp-server-${each.key}-config"
  type     = "pd-balanced"
  size     = data.google_compute_snapshot.sftp_snapshot[each.key].disk_size_gb
  snapshot = data.google_compute_snapshot.sftp_snapshot[each.key].name
  labels = {
    target = "sftp-server-${each.key}-config"
    id     = "sftp-server-${each.key}-config"
  }

  zone = each.value.zone
}



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

resource "google_compute_disk" "postgres_cluster-pv" {
  count = local.postgres_count

  name     = "postgres-data-${count.index}"
  size     = data.google_compute_snapshot.postgres_snapshot[count.index].disk_size_gb
  snapshot = data.google_compute_snapshot.postgres_snapshot[count.index].name
  type     = "pd-balanced"

  zone = element([for i in range(local.postgres_count) : element(local.zones, i % 3)], count.index)

  labels = {
    target = "postgres"
  }
}

# We use it now for cvat 
resource "google_compute_disk" "nfs_pv" {
  name  = "nfs-pv"
  count = local.tarantool_etcd_count
  type  = "pd-balanced"
  size  = "20"
  labels = {
    type = "nfs"
  }
  zone = "us-east4-a"
}
