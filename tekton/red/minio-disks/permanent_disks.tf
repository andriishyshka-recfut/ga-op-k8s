locals {
  settings = jsondecode(file("${path.module}/../../../prod-red.tfvars.json")).Settings.clusters["production"]

  zones = local.settings.persistent_resources.permanentDisks.zones
  minio_count    = local.settings.persistent_resources.permanentDisks.minio.count
  restoreDate = local.settings.persistent_resources.permanentDisks.coldBackupDate
}


data "google_compute_snapshot" "minio_tenant_snapshot" {
  name        = "minio-tenant-red-${count.index}-dr-${local.restoreDate}"
  most_recent = true
  count       = local.minio_count
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
