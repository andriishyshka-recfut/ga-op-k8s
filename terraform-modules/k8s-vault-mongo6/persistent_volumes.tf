data "google_compute_disk" "mongo_data_pv" {
  count = local.pv_disk_count
  name    = "${var.PvcPrefix}-${count.index}"
  project = var.Settings.gcpProject
  zone = element([for i in range(local.pv_disk_count) : element(local.zones, i % 3)], count.index)
}



resource "kubernetes_persistent_volume" "mongo_data_pv" {
  count = local.pv_disk_count
  metadata {
    name = "${var.PvcPrefix}-${count.index}-pv"
    labels = {
      target = var.PvcPrefix
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
        volume_handle = "projects/${var.Settings.gcpProject}/zones/${data.google_compute_disk.mongo_data_pv[count.index].zone}/disks/${var.PvcPrefix}-${count.index}"
      }
    }
  node_affinity {
      required {
        node_selector_term {
          match_expressions {
            key = "topology.gke.io/zone"
            operator = "In"
            values = [ data.google_compute_disk.mongo_data_pv[count.index].zone]
          }
        }
      }
    }
  }
}