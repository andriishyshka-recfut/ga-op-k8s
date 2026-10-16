data "google_compute_disk" "keeper_disk" {
  for_each = local.keeper_disks
  name     = each.value.name
  project  = var.Settings.gcpProject
  zone     = each.value.zone
}

resource "kubernetes_persistent_volume" "keeper_pv" {
  for_each = local.keeper_disks

  metadata {
    name = "${local.keeper_name}-${each.key}-pv"
    labels = {
      target = local.keeper_selector_label
    }
  }

  spec {
    capacity = {
      storage = "${data.google_compute_disk.keeper_disk[each.key].size}Gi"
    }
    access_modes                     = ["ReadWriteOnce"]
    storage_class_name               = ""
    persistent_volume_reclaim_policy = "Retain"

    claim_ref {
      namespace = local.namespace
      name      = each.value.claim_name
    }

    persistent_volume_source {
      csi {
        driver        = "pd.csi.storage.gke.io"
        fs_type       = "ext4"
        volume_handle = "projects/${var.Settings.gcpProject}/zones/${each.value.zone}/disks/${each.value.name}"
      }
    }

    node_affinity {
      required {
        node_selector_term {
          match_expressions {
            key      = "topology.gke.io/zone"
            operator = "In"
            values   = [each.value.zone]
          }
        }
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "keeper_pvc" {
  for_each = local.keeper_disks

  metadata {
    name      = each.value.claim_name
    namespace = local.namespace
    labels = {
      app                                = "${local.keeper_name}-keeper"
      "clickhouse.com/keeper-replica-id" = each.key
    }
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = ""
    volume_name        = kubernetes_persistent_volume.keeper_pv[each.key].metadata[0].name

    resources {
      requests = {
        storage = local.keeper_storage_size
      }
    }

    selector {
      match_labels = {
        target = local.keeper_selector_label
      }
    }
  }
}
