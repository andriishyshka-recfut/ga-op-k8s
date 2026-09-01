locals {
  pgpool_metrics_enabled                   = lookup(local.postgres_ha_settings, "pgpool_metrics_enabled", false)
  pgpool_metrics_image                     = lookup(local.postgres_ha_settings, "pgpool_metrics_image", "pgpool/pgpool2_exporter:1.2.2")
  pgpool_metrics_port                      = lookup(local.postgres_ha_settings, "pgpool_metrics_port", 9719)
  pgpool_metrics_service_monitor_enabled   = lookup(local.postgres_ha_settings, "pgpool_metrics_service_monitor_enabled", false)
  pgpool_metrics_service_monitor_namespace = lookup(local.postgres_ha_settings, "pgpool_metrics_service_monitor_namespace", "monitoring")
  pgpool_metrics_service_monitor_interval  = lookup(local.postgres_ha_settings, "pgpool_metrics_service_monitor_interval", "30s")
  pgpool_metrics_service_monitor_labels    = lookup(local.postgres_ha_settings, "pgpool_metrics_service_monitor_labels", { release = "prometheus" })
  pgpool_metrics_name                      = "${local.cluster_name}-pgpool-exporter"
  pgpool_service_name                      = "${local.cluster_name}-pgpool"
}

resource "kubernetes_manifest" "pgpool_metrics_deployment" {
  count = local.pgpool_metrics_enabled ? 1 : 0

  manifest = yamldecode(templatefile("${path.module}/pgpool-metrics-deployment.yaml.tftpl", {
    name                = local.pgpool_metrics_name
    namespace           = local.namespace
    image               = local.pgpool_metrics_image
    metrics_port        = local.pgpool_metrics_port
    pgpool_service_name = local.pgpool_service_name
    pgpool_service_port = 5432
    root_secret_name    = local.root_secret_name
  }))

  depends_on = [
    helm_release.postgresql_ha,
    kubernetes_secret.root,
  ]
}

resource "kubernetes_manifest" "pgpool_metrics_service" {
  count = local.pgpool_metrics_enabled ? 1 : 0

  manifest = yamldecode(templatefile("${path.module}/pgpool-metrics-service.yaml.tftpl", {
    name         = local.pgpool_metrics_name
    namespace    = local.namespace
    metrics_port = local.pgpool_metrics_port
  }))

  depends_on = [
    kubernetes_manifest.pgpool_metrics_deployment,
  ]
}

resource "kubernetes_manifest" "pgpool_metrics_service_monitor" {
  count = local.pgpool_metrics_enabled && local.pgpool_metrics_service_monitor_enabled ? 1 : 0

  manifest = yamldecode(templatefile("${path.module}/pgpool-metrics-servicemonitor.yaml.tftpl", {
    name                      = local.pgpool_metrics_name
    namespace                 = local.namespace
    service_monitor_namespace = local.pgpool_metrics_service_monitor_namespace
    service_monitor_interval  = local.pgpool_metrics_service_monitor_interval
    service_monitor_labels    = local.pgpool_metrics_service_monitor_labels
  }))

  depends_on = [
    kubernetes_manifest.pgpool_metrics_service,
  ]
}
