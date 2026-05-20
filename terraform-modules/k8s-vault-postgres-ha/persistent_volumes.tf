data "google_compute_disk" "postgresql_ha_disk" {
  count   = local.disk_count
  name    = "${local.disk_prefix}-${count.index}"
  project = var.Settings.gcpProject
  zone    = element([for i in range(local.disk_count) : element(local.zones, i % 3)], count.index)
}

resource "kubernetes_persistent_volume" "postgresql_ha_pv" {
  count = local.disk_count

  metadata {
    name = "${local.cluster_name}-${count.index}-pv"

    labels = {
      target = local.pv_selector_label
    }
  }

  spec {
    capacity = {
      storage = "${data.google_compute_disk.postgresql_ha_disk[count.index].size}Gi"
    }

    access_modes                     = ["ReadWriteOnce"]
    storage_class_name               = ""
    persistent_volume_reclaim_policy = "Retain"
    claim_ref {
      namespace = local.namespace
      name      = "${local.pv_claim_name_prefix}-${count.index}"
    }

    persistent_volume_source {
      csi {
        driver        = "pd.csi.storage.gke.io"
        fs_type       = "ext4"
        volume_handle = "projects/${var.Settings.gcpProject}/zones/${data.google_compute_disk.postgresql_ha_disk[count.index].zone}/disks/${data.google_compute_disk.postgresql_ha_disk[count.index].name}"
      }
    }

    node_affinity {
      required {
        node_selector_term {
          match_expressions {
            key      = "topology.gke.io/zone"
            operator = "In"
            values   = [data.google_compute_disk.postgresql_ha_disk[count.index].zone]
          }
        }
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "postgresql_ha_pvc" {
  count = local.disk_count

  metadata {
    name      = "${local.pv_claim_name_prefix}-${count.index}"
    namespace = local.namespace
  }

  spec {
    access_modes = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = "${data.google_compute_disk.postgresql_ha_disk[count.index].size}Gi"
      }
    }

    selector {
      match_labels = {
        target = local.pv_selector_label
      }
    }

    storage_class_name = ""
    volume_name        = kubernetes_persistent_volume.postgresql_ha_pv[count.index].metadata.0.name
  }
}

# Bitnami postgresql-ha consumes precreated PVCs, so the HA module keeps both PV and PVC resources.
