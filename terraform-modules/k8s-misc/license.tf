resource "kubernetes_secret" "license" {

  count = local.trial_licenses
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
  depends_on = [ null_resource.ansible_eck_crd_playbook ]
}
