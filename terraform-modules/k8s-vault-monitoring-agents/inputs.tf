locals {
  filebeat_groups         = "workloads"
  namespace               = "monitoring"
  filebeat_daemonset_name = "log-beat-filebeat"
  version                 = var.Settings.clusters[var.Cluster][var.Color].elasticsearch.cluster.mon
}