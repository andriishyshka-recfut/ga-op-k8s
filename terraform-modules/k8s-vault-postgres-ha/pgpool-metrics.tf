locals {
  pgpool_metrics_enabled               = lookup(local.postgres_ha_settings, "pgpool_metrics_enabled", false)
  pgpool_metrics_image                 = lookup(local.postgres_ha_settings, "pgpool_metrics_image", "pgpool/pgpool2_exporter:1.2.2")
  pgpool_metrics_port                  = lookup(local.postgres_ha_settings, "pgpool_metrics_port", 9719)
  pgpool_metrics_pod_monitor_enabled   = lookup(local.postgres_ha_settings, "pgpool_metrics_pod_monitor_enabled", false)
  pgpool_metrics_pod_monitor_namespace = lookup(local.postgres_ha_settings, "pgpool_metrics_pod_monitor_namespace", "monitoring")
  pgpool_metrics_pod_monitor_interval  = lookup(local.postgres_ha_settings, "pgpool_metrics_pod_monitor_interval", "30s")
  pgpool_metrics_pod_monitor_labels    = lookup(local.postgres_ha_settings, "pgpool_metrics_pod_monitor_labels", { release = "prometheus" })
  pgpool_metrics_name                  = "${local.cluster_name}-pgpool-exporter"
}

# The exporter itself runs as a sidecar inside each pgpool pod (see the
# pgpool.sidecars block in values.yaml.tftpl) so every replica gets its own
# metrics instead of one exporter pinned to whichever pod a shared Service
# happened to route its long-lived connection to. Only the scrape config
# (PodMonitor) is managed here.
resource "kubernetes_manifest" "pgpool_metrics_pod_monitor" {
  count = local.pgpool_metrics_enabled && local.pgpool_metrics_pod_monitor_enabled ? 1 : 0

  manifest = yamldecode(templatefile("${path.module}/pgpool-metrics-podmonitor.yaml.tftpl", {
    name                  = local.pgpool_metrics_name
    namespace             = local.namespace
    cluster_name          = local.cluster_name
    pod_monitor_namespace = local.pgpool_metrics_pod_monitor_namespace
    pod_monitor_interval  = local.pgpool_metrics_pod_monitor_interval
    pod_monitor_labels    = local.pgpool_metrics_pod_monitor_labels
  }))

  depends_on = [
    helm_release.postgresql_ha,
  ]
}
