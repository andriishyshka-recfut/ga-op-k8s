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
    templatefile("${path.module}/values.yaml.tftpl", {
      auth_secret_name                    = local.auth_secret_name
      cluster_name                        = local.cluster_name
      database                            = local.database
      pgpool_image_registry               = local.pgpool_image_registry
      pgpool_image_repository             = local.pgpool_image_repository
      pgpool_image_tag                    = local.pgpool_image_tag
      pgpool_custom_users_secret_name     = length(local.db_user_names) > 0 ? local.pgpool_custom_users_secret_name : ""
      pgpool_pod_anti_affinity_preset     = local.pgpool_pod_anti_affinity_preset
      pgpool_replicas                     = local.pgpool_replicas
      pgpool_pdb_create                   = local.pgpool_pdb_create
      pgpool_pdb_min_available            = local.pgpool_pdb_min_available
      pgpool_resources                    = local.pgpool_resources
      postgres_replicas                   = local.postgres_replicas
      postgresql_image_registry           = local.postgresql_image_registry
      postgresql_image_repository         = local.postgresql_image_repository
      postgresql_image_tag                = local.postgresql_image_tag
      postgresql_pod_anti_affinity_preset = local.postgresql_pod_anti_affinity_preset
      postgresql_pdb_create               = local.postgresql_pdb_create
      postgresql_pdb_min_available        = local.postgresql_pdb_min_available
      postgresql_resources                = local.postgresql_resources
      root_username                       = data.vault_generic_secret.root_user.data.username
      storage_size                        = local.storage_size
      pv_selector_label                   = local.pv_selector_label
    })
  ]

  depends_on = [
    kubernetes_secret.postgresql_ha_auth,
    kubernetes_secret.pgpool_custom_users,
    kubernetes_secret.root,
    kubernetes_secret.db_users,
    kubernetes_persistent_volume.postgresql_ha_pv,
    kubernetes_persistent_volume_claim.postgresql_ha_pvc,
  ]
}
