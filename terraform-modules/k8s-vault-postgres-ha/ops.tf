resource "kubernetes_manifest" "db_bootstrap" {
  count = local.enable_db_bootstrap && length(local.database_names) > 0 ? 1 : 0

  manifest = yamldecode(templatefile("${path.module}/db-bootstrap-job.yaml.tftpl", {
    namespace             = local.namespace
    job_name              = local.db_bootstrap_job_name
    image                 = local.db_bootstrap_image
    tag                   = local.db_bootstrap_tag
    host                  = local.db_bootstrap_host
    port                  = local.db_bootstrap_port
    database              = local.db_bootstrap_database
    root_secret_name      = local.root_secret_name
    bootstrap_secret_name = local.db_bootstrap_secret_name
  }))

  depends_on = [
    helm_release.postgresql_ha,
    kubernetes_secret.root,
    kubernetes_secret.db_bootstrap_sql,
  ]
}
