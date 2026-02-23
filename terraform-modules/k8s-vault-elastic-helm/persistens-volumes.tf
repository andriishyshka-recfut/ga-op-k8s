resource "kubernetes_persistent_volume" "elastic_pv" {
  for_each = local.persistentVolumesDisks
  metadata {
    name = "elastic-${each.key}-pv"
    labels = {
      target = "elastic-${each.key}"
      elastic = local.globalSettings.clusterName
    }
  }
  spec {
    capacity = {
      storage = each.value.size
    }
    access_modes = ["ReadWriteOnce"]
    claim_ref {
      namespace = local.globalSettings.namespace
      name      = "${local.globalSettings.clusterName}-${each.value.name}-${local.globalSettings.clusterName}-${each.value.name}-${each.value.index}"
    }
    persistent_volume_source {
      csi {
        driver        = "pd.csi.storage.gke.io"
        volume_handle = "projects/${var.Settings.gcpProject}/zones/${element([for i in range(each.value.count) : element(["us-east4-a", "us-east4-b", "us-east4-c"], i % 3)], each.value.index)}/disks/elastic-${each.key}"
      }
    }
    node_affinity {
      required {
        node_selector_term {
          match_expressions {
            key      = "topology.gke.io/zone"
            operator = "In"
            values   = ["${element([for i in range(each.value.count) : element(["us-east4-a", "us-east4-b", "us-east4-c"], i % 3)], each.value.index)}"]
          }
        }
      }
    }
  }
}
resource "kubernetes_persistent_volume_claim" "elasticsearch" {
  for_each         = local.persistentVolumesDisks
  wait_until_bound = false
  metadata {
    name      = "${local.globalSettings.clusterName}-${each.value.name}-${local.globalSettings.clusterName}-${each.value.name}-${each.value.index}"
    namespace = local.globalSettings.namespace
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = each.value.size
      }
    }
  }
  depends_on = [ kubernetes_persistent_volume.elastic_pv ]
}

output "test" {
  value = zipmap(flatten([for item in local.persistentVolumes : keys(item)]), flatten([for item in local.persistentVolumes : values(item)]))
}