locals {
  settings = jsondecode(file("${path.module}/../../../config.tfvars.json")).Settings.clusters["sandbox"]

  kafka_count = 3
  mongo_count = local.settings.mongo.magescanner.replicas
  mongo_prefix = local.settings.mongo.magescanner.pvcPrefix
  mongo_auth_count = local.settings.mongo.auth.replicas
  mongo_auth_prefix = local.settings.mongo.auth.pvcPrefix
  tarantool_count = 1
  sonarqube_count = 1
  sftp = local.settings.sftp-server
  # mongoDiskSize = trim(local.settings.mongo.magescanner.volumeSize, "Gi")
  # mongoAuthDiskSize = trim(local.settings.mongo.magescanner.volumeSize, "Gi")
  restoreDate = "2023-06-05"

}


########
#   Set "restoreDate" (yyyy-mm-dd) to recover data as of that day
########

data "google_compute_snapshot" "tarantool_snapshot" {
  name        = "tarantool-data-dr-${local.restoreDate}"
  most_recent = true
  count = local.tarantool_count
}

data "google_compute_snapshot" "kafka_snapshot" {
  name        = "kafka-data-${count.index}-maintenance-${local.restoreDate}"
  most_recent = true
  count = local.kafka_count
}

data "google_compute_snapshot" "kafka_zookeeper_snapshot" {
  name        = "zookeeper-data-${count.index}-dr-${local.restoreDate}"
  most_recent = true
  count = local.kafka_count
}

data "google_compute_snapshot" "mongo_snapshot" {
  name        = "${local.mongo_prefix}-${count.index}-dr-${local.restoreDate}"
  most_recent = true
  count = local.mongo_count
}

data "google_compute_snapshot" "mongo_auth_snapshot" {
  name        = "${local.mongo_auth_prefix}-${count.index}-dr-${local.restoreDate}"
  most_recent = true
  count = local.mongo_auth_count
}

data "google_compute_snapshot" "sftp_snapshot" {
  for_each = local.sftp
  name        = "${each.key}-config-dr-${local.restoreDate}"
  most_recent = true
}

data "google_compute_snapshot" "sonarqube_postgres_snapshot" {
  name        = "sonarqube-postgres-${count.index}-adhoc"
  most_recent = true
  count = local.sonarqube_count




resource "google_compute_region_disk" "mongo_pv" {
  name     = "${local.mongo_prefix}-${count.index}"
  count    = local.mongo_count
  type     = "pd-balanced"
  size     = data.google_compute_snapshot.mongo_snapshot[count.index].disk_size_gb
  snapshot = data.google_compute_snapshot.mongo_snapshot[count.index].name
  labels = {
    target = local.mongo_prefix
    id     = "${local.mongo_prefix}-${count.index}"
  }

  region        = "us-east4"
  replica_zones = ["us-east4-a", "us-east4-b"]
}

resource "google_compute_region_disk" "mongo_auth_pv" {
  name     = "${local.mongo_auth_prefix}-${count.index}"
  count    = local.mongo_count
  type     = "pd-balanced"
  size     = data.google_compute_snapshot.mongo_auth_snapshot[count.index].disk_size_gb
  snapshot = data.google_compute_snapshot.mongo_auth_snapshot[count.index].name
  labels = {
    target = local.mongo_auth_prefix
    id     = "${local.mongo_auth_prefix}-${count.index}"
  }

  region        = "us-east4"
  replica_zones = ["us-east4-a", "us-east4-b"]
}

resource "google_compute_region_disk" "kafka_pv" {
  name     = "kafka-data-${count.index}"
  count    = local.kafka_count
  type     = "pd-balanced"
  size     = 230
  snapshot = data.google_compute_snapshot.kafka_snapshot[count.index].name
  labels = {
    target = "kafka-data"
    id     = "kafka-data-${count.index}"
  }

  region        = "us-east4"
  replica_zones = ["us-east4-a", "us-east4-b"]
}

resource "google_compute_region_disk" "kafka_zookeeper_pv" {
  name     = "kafka-zookeeper-${count.index}"
  count    = local.kafka_count
  type     = "pd-balanced"
  size     = data.google_compute_snapshot.kafka_zookeeper_snapshot[count.index].disk_size_gb
  snapshot = data.google_compute_snapshot.kafka_zookeeper_snapshot[count.index].name
  labels = {
    target = "kafka-zookeeper"
    id     = "kafka-zookeeper-${count.index}"
  }

  region        = "us-east4"
  replica_zones = ["us-east4-a", "us-east4-b"]
}


resource "google_compute_region_disk" "tarantool_pv" {
  name     = "tarantool-data-${count.index}"
  count    = local.tarantool_count
  type     = "pd-balanced"
  size     = data.google_compute_snapshot.tarantool_snapshot[count.index].disk_size_gb
  snapshot = data.google_compute_snapshot.tarantool_snapshot[count.index].name
  labels = {
    target = "tarantool-data"
    id     = "tarantool-data-${count.index}"
  }

  region        = "us-east4"
  replica_zones = ["us-east4-a", "us-east4-b"]
}


resource "google_compute_region_disk" "sonarqube_postgres_pv" {
  name     = "sonarqube-postgres-${count.index}"
  count    = local.sonarqube_count
  type     = "pd-balanced"
  # size     = 20
  size     = data.google_compute_snapshot.sonarqube_postgres_snapshot[count.index].disk_size_gb
  snapshot = data.google_compute_snapshot.sonarqube_postgres_snapshot[count.index].name
  labels = {
    target = "sonarqube-postgres"
    id     = "sonarqube-postgres-${count.index}"
  }

  region        = "us-east4"
  replica_zones = ["us-east4-a", "us-east4-b"]
}

resource "google_compute_region_disk" "sftp_pv" {
  for_each = local.sftp
  name     = "sftp-server-${each.key}-config"
  type     = "pd-balanced"
  size     = 10
  snapshot = data.google_compute_snapshot.sftp_snapshot[each.key].name
  labels = {
    target = "sftp-server-${each.key}-config"
    id     = "sftp-server-${each.key}-config"
  }

  region        = "us-east4"
  replica_zones = ["us-east4-a", "us-east4-b"]
}