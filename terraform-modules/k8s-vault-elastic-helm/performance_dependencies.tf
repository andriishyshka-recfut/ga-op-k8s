locals {
  configPerformance = <<EOF
    bootstrap.memory_lock: true
    action.destructive_requires_name: true
    http.max_content_length: 256mb
    xpack.monitoring.collection.enabled: true 
    xpack.monitoring.elasticsearch.collection.enabled: false
EOF
}
