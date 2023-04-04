variable "plantuml_list" {}
locals {
  namespace = "gitlab"
  plantuml_values = {
    plantuml-name = "main"
    cpu_request = "350m"
    memory_request = "128Mi"
    cpu_limit = "700m"
    memory_limit = "512Mi"
    autoscaling_enabled = true
    autoscaling_min_replicas = 1
    autoscaling_max_replicas = 2
    target_cpu_utilazation = 90
    target_memory_utilization = 90
  }
}