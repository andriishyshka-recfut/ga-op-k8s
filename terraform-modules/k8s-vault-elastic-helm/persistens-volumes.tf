resource "kubernetes_persistent_volume_claim" "elsticsearch" {
  for_each         = zipmap(flatten([for item in local.persistentVolumes : keys(item)]), flatten([for item in local.persistentVolumes : values(item)]))
  wait_until_bound = false
  metadata {
    name      = each.key
    namespace = local.globalSettings.namespace
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = each.value
      }
    }
  }
}
