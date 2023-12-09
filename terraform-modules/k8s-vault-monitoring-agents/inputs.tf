locals {
  filebeat_groups = "workloads"
  version = var.Settings.clusters[var.Cluster][var.Color].elasticsearch.cluster.mon
}