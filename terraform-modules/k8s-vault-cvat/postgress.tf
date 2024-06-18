resource "kubernetes_persistent_volume" "postgress_pv" {
  metadata {
    name = "cvat-postgresql-pv"
    labels = {
      target = "cvat-postgresql"
    }
  }
  spec {
    capacity = {
      storage = "8Gi"
    }
    access_modes = ["ReadWriteOnce"]
    claim_ref {
      namespace = local.namespace
      name      = "data-cvat-postgresql-0"
    }
    persistent_volume_source {
      csi {
        driver        = "pd.csi.storage.gke.io"
        volume_handle = "projects/${var.Settings.gcpProject}/zones/us-east4-a/disks/cvat-postgresql"
      }
    }
    node_affinity {
      required {
        node_selector_term {
          match_expressions {
            key      = "topology.gke.io/zone"
            operator = "In"
            values   = ["us-east4-a"]
          }
        }
      }
    }
  }
}
