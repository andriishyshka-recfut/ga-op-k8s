
resource "kubernetes_persistent_volume" "minio_tenant_pv" {
  count = local.pv_disk_count
  metadata {
    name = "minio-tenant-data-${count.index}-pv"
    labels = {
      target = "minio-tenant"
    }
  }
  spec {
    capacity = {
      storage = local.diskSize
    }
    access_modes = ["ReadWriteOnce"]
    claim_ref {
      namespace = local.minioNs
      name = "data-minio-tenant-pool-1-${count.index}"
    }
    persistent_volume_source{
      csi {
        driver = "pd.csi.storage.gke.io"
        volume_handle = "projects/${var.Settings.gcpProject}/zones/${element([for i in range(local.pv_disk_count) : element(["us-east4-a", "us-east4-b", "us-east4-c"], i % 3)], count.index)}/disks/minio-red-pv-${count.index}"
      }
    }
    node_affinity {
      required {
        node_selector_term {
          match_expressions {
            key = "topology.gke.io/zone"
            operator = "In"
            values = [ "${element([for i in range(local.pv_disk_count) : element(["us-east4-a", "us-east4-b", "us-east4-c"], i % 3)], count.index)}"]
          }
        }
      }
    }
  }
}


resource "kubernetes_persistent_volume_claim" "minio_tenant_pvc" {
    count = local.pv_disk_count

  metadata {
    name = "data0-minio-tenant-pool-1-${count.index}"
    namespace = local.minioNs
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = local.diskSize
      }
    }
    selector {
      match_labels = {
        target = "minio-tenant"
      }
    }
    storage_class_name = ""
    # volume_name = "minio-tenant-data-${count.index}-pv"
    volume_name = "${kubernetes_persistent_volume.minio_tenant_pv[count.index].metadata.0.name}"
  }
  depends_on = [ kubernetes_persistent_volume.minio_tenant_pv ]
}

