resource "kubernetes_manifest" "limitrange_tekton" {
  manifest = {
    "apiVersion" = "v1"
    "kind"       = "LimitRange"
    "metadata" = {
      "name"      = "limitrange-tekton"
      "namespace" = "tekton-tasks"
    }
    "spec" = {
      "limits" = [
        {
          "default" = {
            "cpu"    = "2"
            "memory" = "2Gi"
          }
          "defaultRequest" = {
            "cpu"    = "2"
            "memory" = "2Gi"
          }
          "type" = "Container"
        },
      ]
    }
  }
}
