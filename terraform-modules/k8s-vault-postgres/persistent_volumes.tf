data "google_compute_disk" "postgres_pv" {
  count   = local.disk_count
  name    = "${local.disk_prefix}-${count.index}"
  project = var.Settings.gcpProject
  zone    = element([for i in range(local.disk_count) : element(local.zones, i % 3)], count.index)
}

resource "kubernetes_persistent_volume" "postgres_pv" {
  count = local.disk_count
  metadata {
    name = "${local.cluster_name}-${count.index}-pv"
    labels = {
      target = local.pv_selector_label
    }
  }
  spec {
    capacity = {
      storage = "${data.google_compute_disk.postgres_pv[count.index].size}Gi"
    }
    access_modes = ["ReadWriteOnce"]
    claim_ref {
      namespace = local.namespace
      name      = "${local.cluster_name}-${count.index + 1}"
    }
    persistent_volume_source {
      csi {
        driver        = "pd.csi.storage.gke.io"
        volume_handle = "projects/${var.Settings.gcpProject}/zones/${data.google_compute_disk.postgres_pv[count.index].zone}/disks/${data.google_compute_disk.postgres_pv[count.index].name}"
      }
    }
    node_affinity {
      required {
        node_selector_term {
          match_expressions {
            key      = "topology.gke.io/zone"
            operator = "In"
            values   = [data.google_compute_disk.postgres_pv[count.index].zone]
          }
        }
      }
    }
  }
}

# CNPG creates and manages its PVCs itself, so we only prebind the backing PVs here.
# resource "kubernetes_persistent_volume_claim" "postgres_pvc" {
#   count = local.disk_count

#   metadata {
#     name      = "${local.cluster_name}-${count.index + 1}"
#     namespace = local.namespace
#     labels = {
#       "cnpg.io/cluster"      = local.cluster_name
#       "cnpg.io/instanceName" = "${local.cluster_name}-${count.index + 1}"
#       "cnpg.io/pvcRole"      = "PG_DATA"
#     }
#     annotations = {
#       "cnpg.io/nodeSerial" = "${count.index + 1}"
#     }
#   }
#   spec {
#     access_modes = ["ReadWriteOnce"]
#     resources {
#       requests = {
#         storage = "${data.google_compute_disk.postgres_pv[0].size}Gi"
#       }
#     }
#     selector {
#       match_labels = {
#         target = local.pv_selector_label
#       }
#     }
#     storage_class_name = ""
#     volume_name        = kubernetes_persistent_volume.postgres_pv[count.index].metadata.0.name
#   }
# }
