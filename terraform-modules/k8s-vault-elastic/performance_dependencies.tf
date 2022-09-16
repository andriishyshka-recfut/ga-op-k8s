locals {
  configPerformance = <<EOF
bootstrap.memory_lock: true
EOF
  performanceConfig = local.performanceSetup == 1 ? { "performance_config" = local.configPerformance } : { "performance_config" = "" }
}
