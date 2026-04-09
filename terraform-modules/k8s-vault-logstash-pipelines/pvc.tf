resource "kubernetes_manifest" "tmp_logstash" {
  for_each = local.logstash_list
  manifest = {
    "apiVersion" = "v1"
    "kind"       = "PersistentVolumeClaim"
    "metadata" = {
      "name"      = "tmp-logstash-${each.key}"
      "namespace" = "${try(each.value.namespace, local.namespace)}"
    }
    "spec" = {
      "accessModes" = [
        "ReadWriteOnce",
      ]
      "resources" = {
        "requests" = {
          "storage" = "3Gi"
        }
      }
      "storageClassName" = "kms-encrypted"
      "volumeMode"       = "Filesystem"
    }
  }
}

