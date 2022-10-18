locals {
  configPerformance = <<EOF
bootstrap.memory_lock: true
action.destructive_requires_name: true
http.max_content_length: 256mb
EOF
  performanceConfig = local.performanceSetup == 1 ? { "performance_config" = local.configPerformance } : { "performance_config" = "" }
}
