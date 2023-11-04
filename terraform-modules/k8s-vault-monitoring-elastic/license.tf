resource "kubernetes_secret" "license" {
  metadata {
    name      = "eck-trial-license"
    namespace = "elastic-system"
    labels = {
      "license.k8s.elastic.co/type" = "enterprise_trial"
    }
    annotations = {
      "elastic.co/eula" = "accepted"
    }
  }
}
