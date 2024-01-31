locals {
  filebeat_groups         = "workloads"
  namespace               = "monitoring"
  filebeat_workload_name  = "log-beat-filebeat"
  filebeat_workload_type  = "daemonset"
  version                 = var.Settings.clusters[var.Cluster][var.Color].versions.elasticsearch.cluster.mon
}