data "google_compute_disk" "kafka_data_pv" {
  count   = local.kafka_count
  name    = "${local.kafka_prefix}-${count.index}"
  project = var.Settings.gcpProject
  zone    = element([for i in range(local.kafka_count) : element(local.zones, i % 3)], count.index)
}

data "google_compute_disk" "kafka_zookeeper_pv" {
  count   = local.kafka_count
  name    = "${local.zookeeper_prefix}-${count.index}"
  project = var.Settings.gcpProject
  zone    = element([for i in range(local.kafka_count) : element(local.zones, i % 3)], count.index)
}

data "google_compute_disk" "mongo_data_pv" {
  count   = local.mongo_count
  name    = "${local.mongo_prefix}-${count.index}"
  project = var.Settings.gcpProject
  zone    = element([for i in range(local.mongo_count) : element(local.zones, i % 3)], count.index)
}

data "google_compute_disk" "mongo_auth_data_pv" {
  count   = local.mongo_auth_count
  name    = "${local.mongo_auth_prefix}-${count.index}"
  project = var.Settings.gcpProject
  zone    = element([for i in range(local.mongo_auth_count) : element(local.zones, i % 3)], count.index)
}

data "google_compute_disk" "minio_data_pv" {
  count   = local.minio_count
  name    = "${local.minio_prefix}-${count.index}"
  project = var.Settings.gcpProject
  zone    = element([for i in range(local.minio_count) : element(local.zones, i % 3)], count.index)
}


resource "google_compute_snapshot" "kafka_snapshot" {
  count       = local.kafka_count
  name        = "${local.kafka_prefix}-${count.index}-dr-${local.backupdate}"
  source_disk = data.google_compute_disk.kafka_data_pv[count.index].self_link
  zone        = data.google_compute_disk.kafka_data_pv[count.index].zone
  labels = {
    target = "kafka-data"
    id     = "${local.kafka_prefix}-${count.index}"
  }
  storage_locations = [local.region]
}

resource "google_compute_snapshot" "kafka_zookeeper_snapshot" {
  count       = local.kafka_count
  name        = "${local.zookeeper_prefix}-${count.index}-dr-${local.backupdate}"
  source_disk = data.google_compute_disk.kafka_zookeeper_pv[count.index].self_link
  zone        = data.google_compute_disk.kafka_zookeeper_pv[count.index].zone
  labels = {
    target = "kafka-zookeeper"
    id     = "${local.zookeeper_prefix}-${count.index}"
  }
  storage_locations = [local.region]
}


resource "google_compute_snapshot" "minio_snapshot" {
  count       = local.minio_count
  name        = "${local.minio_prefix}-${count.index}-dr-${local.backupdate}"
  source_disk = data.google_compute_disk.minio_data_pv[count.index].self_link
  zone        = data.google_compute_disk.minio_data_pv[count.index].zone
  labels = {
    target = "minio-data"
    id     = "${local.minio_prefix}-${count.index}"
  }
  storage_locations = [local.region]
}


resource "google_compute_snapshot" "mongo_snapshot" {
  count       = local.mongo_count
  name        = "${local.mongo_prefix}-${count.index}-dr-${local.backupdate}"
  source_disk = data.google_compute_disk.mongo_data_pv[count.index].self_link
  zone        = data.google_compute_disk.mongo_data_pv[count.index].zone
  labels = {
    target = "mongo-data"
    id     = "${local.mongo_prefix}-${count.index}"
  }
  storage_locations = [local.region]
}

resource "google_compute_snapshot" "mongo_auth_snapshot" {
  count       = local.mongo_auth_count
  name        = "${local.mongo_auth_prefix}-${count.index}-dr-${local.backupdate}"
  source_disk = data.google_compute_disk.mongo_auth_data_pv[count.index].self_link
  zone        = data.google_compute_disk.mongo_auth_data_pv[count.index].zone
  labels = {
    target = "mongo-auth-data"
    id     = "${local.mongo_auth_prefix}-${count.index}"
  }
  storage_locations = [local.region]
}
