
# resource "null_resource" "stop_migrations" {

#   provisioner "local-exec" {
#     interpreter = ["/bin/bash", "-c"]
#     command     = <<COMMAND
#     set -x
#     kubectl --server ${local.gkeClusterConnectionSettings.HOST}  \
#      --token ${local.gkeClusterConnectionSettings.API_KEY}  \
#      --insecure-skip-tls-verify=true  \
#      delete  kafkamirrormaker2s.kafka.strimzi.io --all -n kafka
#     sleep 5

#     kubectl --server ${local.gkeClusterConnectionSettings.HOST}  \
#      --token ${local.gkeClusterConnectionSettings.API_KEY}  \
#      --insecure-skip-tls-verify=true  \
#      delete deploy mongoshake -n mongo

# COMMAND
#   }
# }
