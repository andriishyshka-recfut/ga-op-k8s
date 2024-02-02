locals {
  filebeat_groups            = "workloads"
  namespace                  = "monitoring"
  filebeat_workload_name     = "log-beat-filebeat"
  filebeat_workload_type     = "daemonset"
  filebeat_check_script_path = "../../terraform-modules/k8s-vault-monitoring-agents/filebeats_check.py"
  workload_check_module_path = "../../references/workload-check/workload-readiness.py"
  version                    = var.Settings.clusters[var.Cluster][var.Color].versions.elasticsearch.cluster.mon
}