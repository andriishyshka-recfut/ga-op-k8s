locals {
  settings = jsondecode(file("${path.module}/../../../config.tfvars.json")).Settings.clusters["sandbox"]

  zones = local.settings.persistent_resources.permanentDisks.zones

  mongo_count       = local.settings.mongo.magescanner.replicas
  mongo_prefix      = local.settings.mongo.magescanner.pvcPrefix
  mongo_auth_count  = local.settings.mongo.auth.replicas
  mongo_auth_prefix = local.settings.mongo.auth.pvcPrefix

  kafka_count     = local.settings.persistent_resources.permanentDisks.kafka.count
  tarantool_count = local.settings.persistent_resources.permanentDisks.tarantool.count
  sonarqube_count = local.settings.persistent_resources.permanentDisks.sonarqube.count
  sftp            = local.settings.sftp-server
  minio_count     = local.settings.persistent_resources.permanentDisks.minio.count
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

data "google_compute_snapshot" "tarantool_snapshot" {
  name        = "tarantool-data-dr-${local.restoreDate}"
  most_recent = true
  count       = local.tarantool_count
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
  count = local.minio_count
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
  zone = element([for i in range(local.minio_count) : element(local.zones, i % 3)], count.index)
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
  zone = element([for i in range(local.minio_count) : element(local.zones, i % 3)], count.index)
}


resource "google_compute_disk" "tarantool_pv" {
  name     = "tarantool-data-${count.index}"
  count    = local.tarantool_count
  type     = "pd-balanced"
  size     = data.google_compute_snapshot.tarantool_snapshot[count.index].disk_size_gb
  snapshot = data.google_compute_snapshot.tarantool_snapshot[count.index].name
  labels = {
    target = "tarantool-data"
    id     = "tarantool-data-${count.index}"
  }
  zone = element([for i in range(local.minio_count) : element(local.zones, i % 3)], count.index)
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
