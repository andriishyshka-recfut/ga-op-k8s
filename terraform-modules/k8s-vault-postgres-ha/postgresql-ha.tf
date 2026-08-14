resource "helm_release" "postgresql_ha" {
  name              = local.cluster_name
  chart             = "postgresql-ha"
  repository        = "oci://registry-1.docker.io/bitnamicharts"
  namespace         = local.namespace
  wait              = true
  atomic            = true
  dependency_update = true
  reset_values      = true
  version           = local.chart_version

  values = [
    templatefile("${path.module}/values.yaml.tftpl", local.helm_values_context)
  ]

  depends_on = [
    kubernetes_secret.postgresql_ha_auth,
    kubernetes_secret.root,
    kubernetes_persistent_volume.postgresql_ha_pv,
    kubernetes_persistent_volume_claim.postgresql_ha_pvc,
  ]
}
