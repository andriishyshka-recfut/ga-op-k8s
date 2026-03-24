data "google_compute_disk" "data_disks" {
  for_each = local.services
  name     = "${each.value.prefix}-${each.value.index}"
  project  = var.Settings.gcpProject
  zone     = element([for i in range(each.value.count) : element(local.zones, i % 3)], each.value.index)
}

resource "google_compute_snapshot" "snapshot" {
  for_each    = local.services
  name        = "${each.value.prefix}-${each.value.index}-dr-${local.backupdate}"
  source_disk = data.google_compute_disk.data_disks[each.key].self_link
  zone        = data.google_compute_disk.data_disks[each.key].zone
  labels = {
    target = "${each.value.prefix}"
    id     = "${each.value.prefix}-${each.value.index}"
  }
  storage_locations = [local.region]
}

# data "google_compute_disk" "kafka_data_pv" {
#   count   = local.kafka_count
#   name    = "${local.kafka_prefix}-${count.index}"
#   project = var.Settings.gcpProject
#   zone    = element([for i in range(local.kafka_count) : element(local.zones, i % 3)], count.index)
# }

# data "google_compute_disk" "mongo_data_pv" {
#   count   = local.mongo_count
#   name    = "${local.mongo_prefix}-${count.index}"
#   project = var.Settings.gcpProject
#   zone    = element([for i in range(local.mongo_count) : element(local.zones, i % 3)], count.index)
# }

# data "google_compute_disk" "mongo_auth_data_pv" {
#   count   = local.mongo_auth_count
#   name    = "${local.mongo_auth_prefix}-${count.index}"
#   project = var.Settings.gcpProject
#   zone    = element([for i in range(local.mongo_auth_count) : element(local.zones, i % 3)], count.index)
# }

# data "google_compute_disk" "minio_data_pv" {
#   count   = local.minio_count
#   name    = "${local.minio_prefix}-${count.index}"
#   project = var.Settings.gcpProject
#   zone    = element([for i in range(local.minio_count) : element(local.zones, i % 3)], count.index)
# }

# data "google_compute_disk" "postgres_data_pv" {
#   count   = local.postgres_count
#   name    = "postgres-data-${count.index}"
#   project = var.Settings.gcpProject
#   zone    = element([for i in range(local.minio_count) : element(local.zones, i % 3)], count.index)
# }

# data "google_compute_disk" "tarantool_storage_pv" {
#   count   = local.tarantool_storage_count
#   name    = "tarantool-vortex-storage-${element(range(local.tsc), floor(count.index / 2))}-${count.index % 2}"
#   project = var.Settings.gcpProject
#   zone    = element([for i in range(local.tarantool_storage_count) : element(local.zones, i % 3)], count.index)
# }


# data "google_compute_disk" "tarantool_router_pv" {
#   count   = local.tarantool_router_count
#   name    = "tarantool-vortex-router-${count.index}-0"
#   project = var.Settings.gcpProject
#   zone    = element([for i in range(local.tarantool_router_count) : element(local.zones, i % 3)], count.index)
# }




# resource "google_compute_snapshot" "kafka_snapshot" {
#   count       = local.kafka_count
#   name        = "${local.kafka_prefix}-${count.index}-dr-${local.backupdate}"
#   source_disk = data.google_compute_disk.kafka_data_pv[count.index].self_link
#   zone        = data.google_compute_disk.kafka_data_pv[count.index].zone
#   labels = {
#     target = "kafka-data"
#     id     = "${local.kafka_prefix}-${count.index}"
#   }
#   storage_locations = [local.region]
# }


# resource "google_compute_snapshot" "minio_snapshot" {
#   count       = local.minio_count
#   name        = "${local.minio_prefix}-${count.index}-dr-${local.backupdate}"
#   source_disk = data.google_compute_disk.minio_data_pv[count.index].self_link
#   zone        = data.google_compute_disk.minio_data_pv[count.index].zone
#   labels = {
#     target = "minio-data"
#     id     = "${local.minio_prefix}-${count.index}"
#   }
#   storage_locations = [local.region]
# }


# resource "google_compute_snapshot" "mongo_snapshot" {
#   count       = local.mongo_count
#   name        = "${local.mongo_prefix}-${count.index}-dr-${local.backupdate}"
#   source_disk = data.google_compute_disk.mongo_data_pv[count.index].self_link
#   zone        = data.google_compute_disk.mongo_data_pv[count.index].zone
#   labels = {
#     target = "mongo-data"
#     id     = "${local.mongo_prefix}-${count.index}"
#   }
#   storage_locations = [local.region]
# }

# resource "google_compute_snapshot" "mongo_auth_snapshot" {
#   count       = local.mongo_auth_count
#   name        = "${local.mongo_auth_prefix}-${count.index}-dr-${local.backupdate}"
#   source_disk = data.google_compute_disk.mongo_auth_data_pv[count.index].self_link
#   zone        = data.google_compute_disk.mongo_auth_data_pv[count.index].zone
#   labels = {
#     target = "mongo-auth-data"
#     id     = "${local.mongo_auth_prefix}-${count.index}"
#   }
#   storage_locations = [local.region]
# }


# resource "google_compute_snapshot" "postgres_snapshot" {
#   count       = local.postgres_count
#   name        = "postgres-data-${count.index}-dr-${local.backupdate}"
#   source_disk = data.google_compute_disk.postgres_data_pv[count.index].self_link
#   zone        = data.google_compute_disk.postgres_data_pv[count.index].zone
#   labels = {
#     target = "postgres"
#     id     = "postgres-data-${count.index}"
#   }
#   storage_locations = [local.region]
# }

# resource "google_compute_snapshot" "tarantool_router_snapshot" {
#   count       = local.tarantool_router_count
#   name        = "${local.tarantool_router_prefix}-${count.index}-0-dr-${local.backupdate}"
#   source_disk = data.google_compute_disk.tarantool_router_pv[count.index].self_link
#   zone        = data.google_compute_disk.tarantool_router_pv[count.index].zone
#   labels = {
#     target = local.tarantool_router_count
#     id     = "${local.tarantool_router_prefix}-${count.index}-0"
#   }
#   storage_locations = [local.region]
# }


# resource "google_compute_snapshot" "tarantool_storage_snapshot" {
#   count       = local.tarantool_storage_count
#   name        = "${local.tarantool_storage_prefix}-${element(range(local.tsc), floor(count.index / 2))}-${count.index % 2}-dr-${local.backupdate}"
#   source_disk = data.google_compute_disk.tarantool_storage_pv[count.index].self_link
#   zone        = data.google_compute_disk.tarantool_storage_pv[count.index].zone
#   labels = {
#     target = local.tarantool_storage_prefix
#     id     = "${local.tarantool_storage_prefix}-${element(range(local.tsc), floor(count.index / 2))}-${count.index % 2}"
#   }
#   storage_locations = [local.region]
# }
