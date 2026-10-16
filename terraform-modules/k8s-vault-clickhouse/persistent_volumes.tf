data "google_compute_disk" "clickhouse_disk" {
  for_each = local.clickhouse_disks
  name     = each.value.name
  project  = var.Settings.gcpProject
  zone     = each.value.zone
}

resource "kubernetes_persistent_volume" "clickhouse_pv" {
  for_each = local.clickhouse_disks

  metadata {
    name = "${local.cluster_name}-${each.key}-pv"
    labels = {
      target = local.pv_selector_label
    }
  }

  spec {
    capacity = {
      storage = "${data.google_compute_disk.clickhouse_disk[each.key].size}Gi"
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

resource "kubernetes_persistent_volume_claim" "clickhouse_pvc" {
  for_each = local.clickhouse_disks

  metadata {
    name      = each.value.claim_name
    namespace = local.namespace
    labels = {
      app                         = "${local.cluster_name}-clickhouse"
      "clickhouse.com/shard-id"   = tostring(each.value.shard)
      "clickhouse.com/replica-id" = tostring(each.value.replica)
    }
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = ""
    volume_name        = kubernetes_persistent_volume.clickhouse_pv[each.key].metadata[0].name

    resources {
      requests = {
        storage = local.clickhouse_storage_size
      }
    }

    selector {
      match_labels = {
        target = local.pv_selector_label
      }
    }
  }
}
