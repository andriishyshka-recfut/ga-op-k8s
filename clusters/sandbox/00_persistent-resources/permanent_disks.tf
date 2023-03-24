locals {
  settings = jsondecode(file("${path.module}/../../../config.tfvars.json")).Settings.clusters["sandbox"]

  kafka_count = 3
  mongo_count = local.settings.mongo.magescanner.replicas
  tarantool_count = 1
  mongoDiskSize = trim(local.settings.mongo.magescanner.volumeSize, "Gi")
  restoreDate = "24-03-2023"
}


########
#   Set "restoreDate" (dd-mm-yyyy) to recover data as of that day
########

data "google_compute_snapshot" "tarantool_snapshot" {
  name        = "tarantool-data-${count.index}-${local.restoreDate}"
  most_recent = true
  count = local.tarantool_count
}

data "google_compute_snapshot" "kafka_snapshot" {
  name        = "kafka-data-${count.index}-${local.restoreDate}"
  most_recent = true
  count = local.kafka_count
}

data "google_compute_snapshot" "kafka_zookeeper_snapshot" {
  name        = "zookeeper-${count.index}-${local.restoreDate}"
  most_recent = true
  count = local.kafka_count
}













resource "google_compute_region_disk" "mongo_pv" {
  name     = "mongo-data-${count.index}"
  count    = local.mongo_count
  type     = "pd-balanced"
  size     = local.mongoDiskSize
  # snapshot = data.google_compute_snapshot.mongo_snapshot[count.index].name
  labels = {
    target = "mongo-data"
    id     = "mongo-data-${count.index}"
  }

  region        = "us-east4"
  replica_zones = ["us-east4-a", "us-east4-b"]
}

resource "google_compute_region_disk" "kafka_pv" {
  name     = "kafka-data-${count.index}"
  count    = local.kafka_count
  type     = "pd-balanced"
  size     = data.google_compute_snapshot.kafka_snapshot[count.index].disk_size_gb
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


