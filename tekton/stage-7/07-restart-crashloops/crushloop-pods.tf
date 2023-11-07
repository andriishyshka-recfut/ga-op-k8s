resource "null_resource" "crushloop_pod_delete" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<COMMAND
    set -x
    kubectl --server ${local.gkeClusterConnectionSettings.HOST}  \
     --token ${local.gkeClusterConnectionSettings.API_KEY}  --insecure-skip-tls-verify=true \
     get pods -A -o=custom-columns='NAME:metadata.name, NAMERSPACE:metadata.namespace , STATE:status.containerStatuses[*].state.waiting.reason ' | grep CrashLoopBackOff | awk '{print "-n "$2" "$1}' | xargs -n 3\
     kubectl --server ${local.gkeClusterConnectionSettings.HOST}  \
      --token ${local.gkeClusterConnectionSettings.API_KEY}  --insecure-skip-tls-verify=true delete pod
COMMAND
  }
  triggers = {
    always_run = "${timestamp()}"
  }

}
